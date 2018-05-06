# Changelog

## 0.5.0.beta

### 非互換な変更点

* Rails 5.2対応
* Bootstrap 4対応
* Assets Pipeline廃止、Webpacker対応
* Font Awesome 5をデフォルト、configでアイコンを変更可能に

### その他の変更点

* ActiveStorage対応
* decimal対応

## 0.4.4

* link_to_actionのオプションをカスタマイズできるように
* 詳細検索のUI変更、現在の検索条件が見えるように
* 変更後のリダイレクトステータスを303に変更
* DBに存在しないenumerized attributesがデフォルトでソート対象に含まれるのを修正
* crud_formのurlはresourceではなくparamsに依存するように変更
* デフォルトのページネーション件数を設定できるように
* String以外のenumerize検索に対応
* モーダルピッカー追加
* Crud::Wizard追加

## 0.4.3

* Rails 5.1対応
* render_editのlayoutをAjax通信で有無切り替え
* select2_inputで:selected_itemオプション追加(ajax時の初期値設定)
* 一覧のjsリクエストでparams[:template]で切り替えられるように

## 0.4.2

* permissionsのキャッシュ結果が不正だったのを修正

## 0.4.1

* 0.4.0のバグ修正
* select2 ajax時のidMethodを指定できるように

## 0.4.0

### 非互換を含む変更点

* Rails 5対応
    * API modeの場合はgem 'crud_api'
* select2 4.0に更新
* active_model_serializersを0.10に更新
* コントローラとヘルパーからモデルのリフレクション関連のメソッド削除
    * column_metadata, column_type, column_key?, association_key?, association_class, has_nested?
    * 必要な場合はCrud::ModelReflectionを使う
* Authorizationクラスはapp/authorizationsディレクトリに定義するように変更
    * 互換性を保つため、今までと同様コントローラのインナークラスでも読み込まれる
* コントローラのdo_search, do_sortメソッドをdo_queryメソッドに統合
* ヘルパーメソッドのルックアップ時にコントローラの継承関係を考慮するように
    * privateメソッドの引数等が変更

### その他の変更点

* 詳細検索対応
* デフォルトのソートキーと順序が継承されない問題を修正
* crud:scaffoldジェネレータ追加
* jQuery拡張としてcrudSelect2を追加
* helperにcrud_table_optionsメソッドを定義するとcrud_tableのデフォルトオプションとして渡せる。コントローラー毎にも定義可能。
* 検索メソッドはコントローラー以外にモデルのクラスメソッドとしても定義できるように

## 0.3.2

* namespaceモデルでinputのidが不正になるのを修正
* 削除時のエラー表示対応
    * before_destroyでerrors.addしてfalseを返せば表示される
* select2 inputでformのsubmitハンドラが残り続ける問題対策
* 削除時はリファラを元にリダイレクトするように
* STIの関連の扱いを改善
* key!=valueのようなHTTPクエリパラメータで除外検索ができるように
* crud_tableでheaderオプションを渡せるように
* crud_tableのresponsive対応

## 0.3.1

### 非互換な変更点

* link_to_actionの第3引数をurlパラメータからlink_toのオプションに変更
    * urlパラメータを渡したい場合はparamsオプションで渡すことができる
    * その他のオプションはlink_toにそのまま引き渡される

### その他の変更点

* crud_tableヘルパーメソッド追加、indexのviewをヘルパーを使う形に変更
    * modelやcontrollerオプションを指定することで、別画面でも一覧画面をある程度流用できるように
* htmlとjsで表示カラムが異なるバグを修正
* 編集時に作成時と同様にパラメータを渡せるように
* 編集時にバリデーションエラーが発生しても関連が即時saveされるバグを修正
    * 関連のassignはスキップする仕様にしたので、関連オブジェクトの変更後の値に依存した権限制御はできない
* select2のajaxオプションでページネーションが動作しないのを修正
* select2のajaxによる検索時のキーを指定できるように
* do_filterのデフォルト実装を変更し、idsで指定IDの絞り込み検索をできるように
* enumerizeされたカラムは翻訳値または値による完全一致検索をするように
* simple_formのbootstrap_filestyle inputを追加
* multiple select2で空に設定できないバグを修正

## 0.3.0

### 非互換な変更点

* link_to_modalヘルパーの廃止
* デフォルトviewを全体的に見直し、Ajax対応はjsテンプレートで行うように
* CRUDアクションでrespond_toのブロック引数を取るように変更し、format毎の動作をオーバーライドできるように

### その他の変更点

* インスタンス変数 @remote を true にすると一覧画面がAjax対応に(デフォルトではformatがjsのときのみ)
* bootstrap_flash_messagesヘルパーメソッド追加

## 0.2.2

* Ruby 2.2, Rails 4.2 対応
* CSV出力対応
