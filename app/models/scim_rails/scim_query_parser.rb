module ScimRails
  class ScimQueryParser
    attr_accessor :query_elements

    def initialize(query_string)
      self.query_elements = query_string.split(" ")
    end

    def user_attribute
      attribute = attribute_to_sym

      mapped_attribute = user_attribute_mapping(attribute)
      raise ScimRails::ExceptionHandler::InvalidQuery if mapped_attribute.blank?
      mapped_attribute
    end

    def group_attribute
      attribute = attribute_to_sym

      mapped_attribute = group_attribute_mapping(attribute)
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

    def attribute_to_sym
      attribute = query_elements.dig(0)
      raise ScimRails::ExceptionHandler::InvalidQuery if attribute.blank?
      attribute = attribute.to_sym
    end

    def user_attribute_mapping(attribute)
      ScimRails.config.queryable_user_attributes[attribute]
    end

    def group_attribute_mapping(attribute)
      ScimRails.config.queryable_group_attributes[attribute]
    end

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
