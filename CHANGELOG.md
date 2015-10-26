# Changelog

## 0.3.1

### 非互換な変更点

* link_to_actionの第3引数をurlパラメータからlink_toのオプションに変更
** urlパラメータを渡したい場合はparamsオプションで渡すことができる
** その他のオプションはlink_toにそのまま引き渡される
* set_defaultsをbefore_#{action}メソッドの後に呼ぶように変更

### その他の変更点

* crud_tableヘルパーメソッド追加、indexのviewをヘルパーを使う形に変更
** modelやcontrollerオプションを指定することで、別画面でも一覧画面をある程度流用できるように
* htmlとjsで表示カラムが異なるバグを修正
* 編集時に作成時と同様にパラメータを渡せるように

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
