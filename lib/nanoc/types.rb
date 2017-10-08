# frozen_string_literal: true

require 'bigdecimal'

module RDL
  module Annotate
    def type(*args); end

    def var_type(*args); end

    def do_typecheck(*_args)
      raise 'Typecheck failed; RDL not available.'
    end
  end
end

module Nanoc::Types
  def self.setup
    begin
      require 'rdl'
      rdl_available = true
    rescue LoadError
      rdl_available = false
    end

    if rdl_available
      require 'types/core'

      RDL.type :Exception, :initialize, '() -> self'
      RDL.type :Exception, :initialize, '(String) -> self'
      RDL.type :Kernel, :raise, '(Exception) -> %bot'
      RDL.type :Kernel, :raise, '(Class) -> %bot'
    end
  end
end

Nanoc::Types.setup
