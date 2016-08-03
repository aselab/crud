# Changelog

## 0.3.2

* namespaceモデルでinputのidが不正になるのを修正
* 削除時のエラー表示対応
    * before_destroyでerrors.addしてfalseを返せば表示される
* select2 inputでformのsubmitハンドラが残り続ける問題対策
* 削除時はリファラを元にリダイレクトするように
* STIの関連の扱いを改善
* key!=valueのようなHTTPクエリパラメータで除外検索ができるように

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
