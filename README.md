# crud

RailsのDBの[CRUD](https://ja.wikipedia.org/wiki/CRUD)操作を簡単に実装するためのライブラリ。
一覧の検索、ソート、ページネーションや各アクションの認可機能も備える。

## インストール

以下をGemfileに追加してbundle install

```
gem 'crud', git: 'git@bitbucket.org:aselab/crud.git'
# API modeの場合はこちら、以降の設定は不要
gem 'crud_api', git: 'git@bitbucket.org:aselab/crud.git'
```

application.css を application.sassにリネームして以下を追加

```
/*
 *= require crud
*/
@import "bootstrap-sprockets";
@import "font-awesome-sprockets";
@import "bootstrap";
@import "font-awesome";
```

application.js に以下を追加

```
//= require bootstrap-sprockets
//= require crud
```

## Crud::ApplicationController

モデルのCRUD機能を提供するコントローラの基底クラス。
Rails標準の[RESTful](https://ja.wikipedia.org/wiki/REST) routesに則ったアクションを提供する。

| アクション名 | 内容 |
| ------------ | ---- |
| index | 一覧表示 |
| show | 詳細表示 |
| new | 新規作成画面表示 |
| edit | 編集画面表示 |
| create | 新規作成処理 |
| update | 更新処理 |
| destroy | 削除処理 |

それぞれのアクションが実行される時に、set_defaults, before_(アクション名), do_(アクション名) メソッドが呼び出される仕様になっている。
何も実装しなくてもデフォルトルールに従って動作するように作られており、動作をカスタマイズしたい場合だけprotectedのメソッドを定義したり、
各メソッドをオーバーライドして実装すればよい。
最小のコード例:

```ruby
class UsersController < Crud::ApplicationController
  permit_keys :name, :age
end
```

indexアクションについては提供する機能が多いので、do_index内で以下のメソッドを呼び出しており、個別にオーバーライドできるようにしている。

| メソッド名 | 機能 | デフォルト処理 |
| ---------- | ---- | -------------- |
| do_filter | フィルター処理 | params[:except_ids]を除外 |
| do_search | 検索処理 | params[:term]でstring,integer型の更新対象カラムをlike OR検索 |
| do_sort | ソート処理 | params[:sort_key]のparams[:sort_order] (デフォルト昇順)でソート |
| do_page | ページネーション | params[:per] (デフォルト25)件毎のparams[:page]ページ目を検索 |

crudのコントローラに対応するモデルはmodel, indexアクションで表示するデータはresources、その他アクションで扱うデータはresourceを利用する。
これらはhelperメソッドとして定義しているため、controllers, helpers, viewsどこでも使えるようになっている。

デフォルトではmodelはコントローラ名から解決される。例えばUsersControllerならばUserモデルを扱う。
命名規約に反するモデルを扱いたい場合はメソッドをオーバーライドして明示的に指定する。

resourcesにはデフォルトではmodel.allが設定されている。
例えば検索対象をモデル全体ではなく特定の範囲に絞り込みたい場合などは、do_filterメソッドをオーバーライドして絞り込んだ結果を返すように実装する。
resourceにはmodel.find(params[:id])の結果が設定されている。

```ruby
class FoosController < Crud::ApplicationController
  protected
  # デフォルトではFooモデルが扱われるが、別のモデルを扱いたい場合は定義
  def model
    User
  end

  # 一覧で扱う対象を特定のscopeに絞り込みたい場合
  def do_filter
    resources.active unless params[:all]
  end

  # 論理削除にしたい
  def do_destroy
    resource.update_attribute(:deleted_at, DateTime.now)
  end
end
```

### 各アクションの対象カラムリストの指定

permit_keysで更新対象のカラムを指定する。StrongParametersと同様の指定方法。
全アクション共通の対象カラムはmodel_columnsメソッドで定義する。デフォルトはpermit_keysと同じ。
各アクション毎の対象カラムはcolumns_for_(index, show, create, update)で定義する。デフォルトはmodel_columnsと同じ。
一覧表示の各フォーマット毎の出力対象カラムはcolumns_for_(MIMEタイプ)で定義する。デフォルトはcolumns_for_indexと同じ。
検索対象カラムはcolumns_for_searchで定義する。デフォルトはcolumns_for_indexのうちstringまたはinteger型のカラム。

```ruby
class FoosController < Crud::ApplicationController
  permit_keys :column1, :column2, array_column: [], hash_column: [:nested_column1, :nested_column2]

  protected
  def model_columns
    [:column1, :column2]
  end

  # 一覧画面の表示項目
  def columns_for_index
    [:column1, :virtual_column]
  end

  # 新規作成画面の表示項目
  def columns_for_create
    [:column1]
  end

  # CSV出力時の項目
  def columns_for_csv
    model_columns
  end

  # 検索対象のカラム
  def columns_for_search
    [:column1]
  end
end
```

### カラムのhtml表示

一覧や詳細画面で表示されるカラムの内容は、デフォルトではsimple_formatで出力される。
以下の優先順でメソッドを定義して表示内容をカスタマイズすることができる。

1. helperに #{controller_name}_#{column_name}_html という名前のメソッドを実装
2. helperに #{column_name}_html という名前のメソッドを実装
3. modelに #{column_name}_label という名前のメソッドを実装

#### nameカラムをリンク表示にする例

```ruby
module UsersHelper
  def users_name_html(resource, value)
    link_to value, resource
  end
end
```

resourceにはモデルのインスタンスが、valueにはそのカラムに対応する値が渡される。
この例の場合 resource: Userインスタンス, value: nameの値

#### birth_dateカラムを / 区切りの年月日表示にする例

```ruby
# helperに実装
module UsersHelper
  def users_birth_date_html(resource, value)
    value.try(:strftime, "%Y/%m/%d")
  end
end

# modelに実装
class User < ActiveRecord::Base
  def birth_date_label
    birth_date.try(:strftime, "%Y/%m/%d")
  end
end
```

### カラムの編集フォーム表示

編集画面で表示されるカラムの内容は、デフォルトは[simple_form](https://github.com/plataformatec/simple_form#available-input-types-and-defaults-for-each-column-type)と同じだが、日付型はピッカーで表示される。
以下の優先順でhelperメソッドを定義して入力フォームをカスタマイズすることができる。

1. \#{controller_name}_#{column_name}_input という名前のメソッドを実装
2. \#{column_name}_input という名前のメソッドを実装
3. \#{controller_name}_#{column_name}_input_options という名前のメソッドを実装
4. \#{column_name}_input_options という名前のメソッドを実装

#### 性別を選択肢にする例

```ruby
module UsersHelper
  def users_sex_input_options
    { as: :select, collection: [:male, :female] }
  end
end
```

simple_formのinputに渡すオプション値を返すように実装する。

#### 入力フォーム全体を定義する例

```ruby
module UsersHelper
  def users_column1_input(f)
    content_tag(:div) do
      f.text_field(:column1) + javascript_tag("...")
    end
  end
end
```

#### カスタムインプット

* :bootstrap_datepicker
* :bootstrap_timepicker
* :bootstrap_datetimepicker
* :bootstrap_filestyle
* :select2

### 検索条件の指定

一覧に表示されている文字列または数値のカラムが検索対象となる。
検索対象のカラムを変更したい場合はコントローラにcolumns_for_searchメソッドを定義する。

デフォルトでは文字列カラムはlike検索、数値カラムは完全一致で検索される。
検索条件を変更したい場合や、DBに存在しない仮想カラムに検索条件を持たせる場合などには、
search_by_#{column_name} というメソッドをコントローラに定義する。
引数には検索キーワードが渡されるので、それを使って検索条件を返すように実装すればよい。

```ruby
class User < ActiveRecord::Base
  def full_name
    "#{last_name} #{first_name}"
  end
end

class UsersController < Crud::ApplicationController
  protected
  def columns_for_search
    [:full_name, :email]
  end

  def search_by_full_name(term)
    ["last_name LIKE :term OR first_name LIKE :term", term: "%#{term}%"]
  end
end
```

### ソート条件の指定

デフォルトのソート条件の指定することができる。

```ruby
class SampleController < Crud::ApplicationController
  default_sort_key :name
  default_sort_order :desc
end
```

カラム毎にソート条件をカスタマイズしたい場合、sort_by_#{column_name} というメソッドをコントローラに定義する。
引数には:ascまたは:descが渡されるので、それを使ってソート条件を返すように実装すればよい。

```ruby
class UsersController < Crud::ApplicationController
  protected
  def sort_by_full_name(order)
    "last_name #{order}, first_name #{order}"
  end
end
```

### 権限制御

権限制御をしたい場合はコントローラにAuthorizationという名前のインナークラスを定義する。
各アクションの実行を許可するかどうかをメソッド定義してtrue/falseを返すように実装すればよい。

特殊なアクションとして、manageを定義するとcreate, update, destroyの権限をまとめて制御できる。
アクションに対応するメソッドを定義しない場合のデフォルト値はtrueである。

```ruby
class UsersController < Crud::ApplicationController
  class Authorization < Crud::Authorization::Default
    def create?(user)
      false
    end

    def manage?(user)
      user == current_user
    end
  end
end
```

メソッドの引数にはアクションを実行しようとしている対象のレコードが渡される。
また、コントローラのcurrent_userが渡されるため、ログインユーザによる制御も可能。

### 各アクションの表示結果のカスタマイズ

結果のフォーマットはhtml, js, jsonに対応。indexのみcsvにも対応。
htmlとjsはviews/crud/applicationのテンプレートが用いられるため、これをcontrollerに対応するviewとしてコピーして編集すればよい。
jsonは[active_model_serializers](https://github.com/rails-api/active_model_serializers)を用いて出力される。
app/serializersにモデルに対応するシリアライザーを定義すればそれが用いられる。

特定のフォーマットの動作自体を書き換えたい場合、以下のようにアクションのメソッドをオーバーライドしてsuperにブロックを渡すことができる。

```ruby
def create
  super do |format|
    format.html { ... }
  end
end
```

編集画面のキャンセル、作成/更新時のリダイレクト先を変更したい場合、cancel_pathをオーバーライドするとよい。デフォルトでは一覧画面に戻る。
削除時はrequest.refererに戻る。

### ジェネレータ

```
# モデル + crudコントローラ生成
rails generate crud:scaffold User group:references name age:integer
# crudコントローラ生成
rails generate crud:controller Users group_id name age
# crudのviewをapp/views/crud/applicationにコピー
rails generate crud:application_views
# crudのviewをコントローラ単位でコピー
rails generate crud:views users
```
