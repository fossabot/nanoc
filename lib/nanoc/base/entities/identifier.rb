# frozen_string_literal: true

module Nanoc
  class Identifier
    include Comparable
    include Nanoc::Int::ContractsSupport
    extend RDL::Annotate

    # @api private
    class InvalidIdentifierError < ::Nanoc::Error
      extend RDL::Annotate

      type '(String) -> self', typecheck: :spec
      def initialize(string)
        super("Invalid identifier (does not start with a slash): #{string.inspect}")
      end
    end

    # @api private
    class InvalidFullIdentifierError < ::Nanoc::Error
      extend RDL::Annotate

      type '(String) -> self', typecheck: :spec
      def initialize(string)
        super("Invalid full identifier (ends with a slash): #{string.inspect}")
      end
    end

    # @api private
    class InvalidTypeError < ::Nanoc::Error
      extend RDL::Annotate

      type '(Symbol) -> self', typecheck: :spec
      def initialize(type)
        super("Invalid type for identifier: #{type.inspect} (can be :full or :legacy)")
      end
    end

    # @api private
    class InvalidPrefixError < ::Nanoc::Error
      extend RDL::Annotate

      type '(String) -> self', typecheck: :spec
      def initialize(string)
        super("Invalid prefix (does not start with a slash): #{string.inspect}")
      end
    end

    # @api private
    class UnsupportedLegacyOperationError < ::Nanoc::Error
      extend RDL::Annotate

      type '() -> self', typecheck: :spec
      def initialize
        super('Cannot use this method on legacy identifiers')
      end
    end

    # @api private
    class NonCoercibleObjectError < ::Nanoc::Error
      extend RDL::Annotate

      type '(Object) -> self', typecheck: :spec
      def initialize(obj)
        super("#{obj.inspect} cannot be converted into a Nanoc::Identifier")
      end
    end

    var_type :@type, 'Symbol'
    var_type :@string, 'String'

    type '(Nanoc::Identifier or String) -> Nanoc::Identifier', typecheck: :spec
    def self.from(obj)
      case obj
      when Nanoc::Identifier
        obj
      when String
        Nanoc::Identifier.new(obj)
      else
        raise Nanoc::Identifier::NonCoercibleObjectError.new(obj)
      end
    end

    type '(String, type: ?Symbol) -> self', typecheck: :spec
    def initialize(string, type: :full)
      @type = type

      case @type
      when :legacy
        @string = "/#{string}/".gsub(/^\/+|\/+$/, '/').freeze
      when :full
        raise Nanoc::Identifier::InvalidIdentifierError.new(string) if string !~ /\A\//
        raise Nanoc::Identifier::InvalidFullIdentifierError.new(string) if string =~ /\/\z/

        @string = string.dup.freeze
      else
        raise Nanoc::Identifier::InvalidTypeError.new(@type)
      end

      self
    end

    type '(%any) -> %bool', typecheck: :spec
    def ==(other)
      case other
      when Nanoc::Identifier, String
        to_s == other.to_s
      else
        false
      end
    end

    type '(Object) -> %bool', typecheck: :spec
    def eql?(other)
      other.is_a?(self.class) && to_s == other.to_s
    end

    type '() -> Numeric', typecheck: :spec
    def hash
      self.class.hash ^ to_s.hash
    end

    type '(String or Regexp) -> Numeric', typecheck: :spec
    def =~(other)
      Nanoc::Int::Pattern.from(other).match?(to_s) ? 0 : nil
    end

    type '(Object) -> Numeric', typecheck: :spec
    def <=>(other)
      to_s <=> other.to_s
    end

    type '() -> %bool', typecheck: :spec
    # Whether or not this is a full identifier (i.e.includes the extension).
    def full?
      @type == :full
    end

    type '() -> %bool', typecheck: :spec
    # Whether or not this is a legacy identifier (i.e. does not include the extension).
    def legacy?
      @type == :legacy
    end

    type '() -> String', typecheck: :spec
    def chop
      to_s.chop
    end

    type '(String) -> String', typecheck: :spec
    def +(other)
      to_s + other
    end

    type '(String) -> self', typecheck: :spec
    def prefix(string)
      if string !~ /\A\//
        raise Nanoc::Identifier::InvalidPrefixError.new(string)
      end

      Nanoc::Identifier.new(string.sub(/\/+\z/, '') + @string, type: @type)
    end

    type '() -> String', typecheck: :spec
    # The identifier, as string, with the last extension removed
    def without_ext
      unless full?
        raise Nanoc::Identifier::UnsupportedLegacyOperationError
      end

      extname = File.extname(@string)

      if !extname.empty?
        @string[0..-extname.size - 1]
      else
        @string
      end
    end

    type '() -> String or nil', typecheck: :spec
    # The extension, without a leading dot
    def ext
      unless full?
        raise Nanoc::Identifier::UnsupportedLegacyOperationError
      end

      s = File.extname(@string)
      s && s[1..-1]
    end

    type '() -> String', typecheck: :spec
    # The identifier, as string, with all extensions removed
    def without_exts
      extname = exts.join('.')
      if !extname.empty?
        @string[0..-extname.size - 2]
      else
        @string
      end
    end

    type '() -> Array<%bot> or Array<String>', typecheck: :spec
    # The list of extensions, without a leading dot
    def exts
      unless full?
        raise Nanoc::Identifier::UnsupportedLegacyOperationError
      end

      s = File.basename(@string)
      s ? s.split('.', -1).drop(1) : []
    end

    type '() -> Array<%bot> or Array<String>', typecheck: :spec
    def components
      res = to_s.split('/')
      if res.empty?
        []
      else
        res[1..-1]
      end
    end

    type '() -> String', typecheck: :spec
    def to_s
      @string
    end

    type '() -> String', typecheck: :spec
    def to_str
      @string
    end

    type '() -> String', typecheck: :spec
    def inspect
      "<Nanoc::Identifier type=#{@type} #{to_s.inspect}>"
    end
  end
end
