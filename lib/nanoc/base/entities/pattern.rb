# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Pattern
    extend RDL::Annotate

    type '(Nanoc::Int::Pattern or String or Regexp) -> Nanoc::Int::Pattern', typecheck: :spec
    def self.from(obj)
      case obj
      when Nanoc::Int::StringPattern, Nanoc::Int::RegexpPattern
        obj
      when String
        Nanoc::Int::StringPattern.new(obj)
      when Regexp
        Nanoc::Int::RegexpPattern.new(obj)
      else
        raise ArgumentError.new("Do not know how to convert `#{obj.inspect}` into a Nanoc::Pattern")
      end
    end

    type '(%any) -> self', typecheck: :spec
    def initialize(_obj)
      raise NotImplementedError
      self # rubocop:disable Lint/UnreachableCode
    end

    type '(Nanoc::Identifier or String) -> %bool', typecheck: :spec
    def match?(_identifier)
      raise NotImplementedError
    end

    type '(Nanoc::Identifier or String) -> nil or Array<String>', typecheck: :spec
    def captures(_identifier)
      raise NotImplementedError
    end
  end

  # @api private
  class StringPattern < Pattern
    extend RDL::Annotate

    MATCH_OPTS = File::FNM_PATHNAME | File::FNM_EXTGLOB

    var_type :@string, 'String'

    type '(String) -> self', typecheck: :spec
    def initialize(string)
      @string = string
      self
    end

    type '(Nanoc::Identifier or String) -> %bool', typecheck: :spec
    def match?(identifier)
      File.fnmatch(@string, identifier.to_s, Nanoc::Int::StringPattern::MATCH_OPTS)
    end

    type '(Nanoc::Identifier or String) -> nil', typecheck: :spec
    def captures(_identifier)
      nil
    end

    type '() -> String', typecheck: :spec
    def to_s
      @string
    end
  end

  # @api private
  class RegexpPattern < Pattern
    extend RDL::Annotate

    var_type :@regexp, 'Regexp'

    type '(Regexp) -> self', typecheck: :spec
    def initialize(regexp)
      @regexp = regexp
      self
    end

    type '(Nanoc::Identifier or String) -> %bool', typecheck: :spec
    def match?(identifier)
      (identifier.to_s =~ @regexp) != nil
    end

    type '(Nanoc::Identifier or String) -> nil or Array<String>', typecheck: :spec
    def captures(identifier)
      matches = @regexp.match(identifier.to_s)
      matches&.captures
    end

    type '() -> String', typecheck: :spec
    def to_s
      @regexp.to_s
    end
  end
end
