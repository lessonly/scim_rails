module ScimRails
  class ScimQueryParser
    attr_accessor :query_elements, :query_attributes

    def initialize(query_string, queryable_attributes)
      self.query_elements = query_string.split(" ")
      self.query_attributes = queryable_attributes
    end

    def attribute
      attribute = query_elements.dig(0)
      raise ScimRails::ExceptionHandler::InvalidQuery if attribute.blank?
      attribute = attribute.to_sym

      mapped_attribute = query_attributes[attribute]
      raise ScimRails::ExceptionHandler::InvalidQuery if mapped_attribute.blank?
      mapped_attribute
    end

    def operator
      sql_comparison_operator(query_elements.dig(1))
    end

    def parameter
      parameter = query_elements[2..-1].join(" ")
      return if parameter.blank?
      parameter.gsub(/"/, "")
    end

    private

    def sql_comparison_operator(element)
      case element
      when "eq"
        "="
      else
        # TODO: implement additional query filters
        raise ScimRails::ExceptionHandler::InvalidQuery
      end
    end
  end
end
