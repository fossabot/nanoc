# frozen_string_literal: true

module Nanoc
  class ChangesStream
    class ChangesListener
      def initialize(y)
        @y = y
      end

      def unknown
        @y << [:unknown]
      end

      def lib
        @y << [:lib]
      end

      def document_added(type, documents)
        documents.each { |d| @y << [:document_added, type, d] }
      end

      def document_modified(type, documents)
        documents.each { |d| @y << [:document_modified, type, d] }
      end

      def document_deleted(type, identifiers)
        identifiers.each { |i| @y << [:document_deleted, type, i] }
      end

      def to_stop(&block)
        if block_given?
          @to_stop = block
        else
          @to_stop
        end
      end
    end

    def initialize(enum: nil)
      @enum = enum
      @enum ||=
        Enumerator.new do |y|
          @listener = ChangesListener.new(y)
          yield(@listener)
        end.lazy
    end

    def stop
      @listener&.to_stop&.call
    end

    def map
      self.class.new(enum: @enum.map { |e| yield(e) })
    end

    def to_enum
      @enum
    end

    def each
      @enum.each { |e| yield(e) }
      nil
    end
  end
end
