module Crud
  module Serialization
    extend ActiveSupport::Concern

    def serializer
      Crud::DefaultSerializer
    end

    def serialization_scope
      {}
    end

    def json_metadata
      {}
    end

    def generate_json(items, options = nil)
      options = {
        scope: serialization_scope,
        serializer: serializer
      }.merge(options || {})
      if items.respond_to?(:to_ary)
        result = ActiveModel::Serializer::CollectionSerializer.new(items.to_ary, options).as_json
        if items.is_a?(Kaminari::PageScopeMethods)
          result = {
            items: result,
            meta: json_metadata.merge(
              per_page: items.limit_value,
              total_count: items.total_count,
              total_pages: items.total_pages,
              current_page: items.current_page
            )
          }
        end
        result
      else
        ActiveModelSerializers::SerializableResource.new(items, options).as_json
      end
    end

    def json_errors_options(item)
      { json: json_errors(item), status: :unprocessable_entity }
    end

    def generate_csv(columns, items, options)
      options ||= {}
      header = options[:header].to_s != "false"
      encoding = options[:encoding]
      encoding = Encoding.find(encoding) rescue nil if encoding
      row_sep = {crlf: "\r\n", cr: "\r", lf: "\n"}[options[:line_break].try(:to_sym)]
      generate_options = row_sep ? {row_sep: row_sep} : {}

      data = CSV.generate(generate_options) do |csv|
        csv << columns.map {|c| model.human_attribute_name(c)} if header
        items.each do |item|
          csv << columns.map {|c| csv_column(item, c)}
        end
      end

      if encoding
        data.encode(encoding)
      else
        # Excelでの文字化け回避のためUTF-8 BOMを付加する
        "\xEF\xBB\xBF" + data
      end
    end

    #
    # csv_column_:column_name という名前のメソッドを定義すると、
    # カラムのcsv出力結果をカスタマイズできる。
    #
    #  def csv_column_value(item)
    #    format("%04d", item.value)
    #  end
    #
    def csv_column(item, column)
      method = "csv_column_#{column}"
      respond_to?(method, true) ? send(method, item) : item.send(column)
    end

    private
    def json_errors(item)
      errors = {}
      ref = ModelReflection[item]
      if ref.activerecord?
        item.errors.messages.each do |key, messages|
          key = key.to_s.split(".").first.to_sym
          next if errors.has_key?(key)
          if item.association_cached?(key)
            e = association_json_errors(item.send(key))
            errors[key] = e || messages
          else
            errors[key] = messages
          end
        end
      elsif ref.mongoid?
        errors = item.errors.messages.dup
        item.associations.keys.each do |key|
          key = key.to_sym
          next unless errors.has_key?(key)
          e = association_json_errors(item.send(key))
          errors[key] = e if e
        end
      end
      errors
    end

    def association_json_errors(association)
      # 無限ループしないように
      @error_classes ||= []
      return if @error_classes.include?(association.class)
      @error_classes << association.class

      errors = if association.respond_to?(:to_ary)
        association.each.with_index.each_with_object({}) do |(o, i), h|
          h[i] = json_errors(o) unless o.errors.empty?
        end
      else
        json_errors(association)
      end
      errors.empty? ? nil : errors
    end
  end
end
