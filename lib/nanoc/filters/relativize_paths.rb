# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class RelativizePaths < Nanoc::Filter
    identifier :relativize_paths

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    SELECTORS = ['*/@href', '*/@src', 'object/@data', 'param[@name="movie"]/@content', 'form/@action', 'comment()'].freeze

    # Relativizes all paths in the given content, which can be HTML, XHTML, XML
    # or CSS. This filter is quite useful if a site needs to be hosted in a
    # subdirectory instead of a subdomain. In HTML, all `href` and `src`
    # attributes will be relativized. In CSS, all `url()` references will be
    # relativized.
    #
    # @param [String] content The content to filter
    #
    # @option params [Symbol] :type The type of content to filter; can be
    #   `:html`, `:xhtml`, `:xml` or `:css`.
    #
    # @option params [Array] :select The XPath expressions that matches the
    #   nodes to modify. This param is useful only for the `:html`, `:xml` and
    #   `:xhtml` types.
    #
    # @option params [Hash] :namespaces The pairs `prefix => uri` to define
    #   any namespace you want to use in the XPath expressions. This param
    #   is useful only for the `:xml` and `:xhtml` types.
    #
    # @return [String] The filtered content
    def run(content, params = {})
      Nanoc::Extra::JRubyNokogiriWarner.check_and_warn

      # Set assigns so helper function can be used
      @item_rep = assigns[:item_rep] if @item_rep.nil?

      # Filter
      case params[:type]
      when :css
        relativize_css(content)
      when :html, :html5, :xml, :xhtml
        relativize_html_like(content, params)
      else
        raise 'The relativize_paths needs to know the type of content to ' \
          'process. Pass a :type to the filter call (:html for HTML, ' \
          ':xhtml for XHTML, :xml for XML, or :css for CSS).'
      end
    end

    protected

    def relativize_css(content)
      # FIXME: parse CSS the proper way using csspool or something
      content.gsub(/url\((['"]?)(\/(?:[^\/].*?)?)\1\)/) do
        quote = Regexp.last_match[1]
        path = Regexp.last_match[2]
        'url(' + quote + relative_path_to(path) + quote + ')'
      end
    end

    def relativize_html_like(content, params)
      selectors             = params.fetch(:select, SELECTORS)
      namespaces            = params.fetch(:namespaces, {})
      type                  = params.fetch(:type)
      nokogiri_save_options = params.fetch(:nokogiri_save_options, nil)

      parser = parser_for(type)
      content = fix_content(content, type)

      nokogiri_process(content, selectors, namespaces, parser, type, nokogiri_save_options)
    end

    def parser_for(type)
      case type
      when :html
        require 'nokogiri'
        ::Nokogiri::HTML
      when :html5
        require 'nokogumbo'
        ::Nokogiri::HTML5
      when :xml
        require 'nokogiri'
        ::Nokogiri::XML
      when :xhtml
        require 'nokogiri'
        ::Nokogiri::XML
      end
    end

    def fix_content(content, type)
      case type
      when :xhtml
        # FIXME: cleanup because it is ugly
        # this cleans the XHTML namespace to process fragments and full
        # documents in the same way. At least, Nokogiri adds this namespace
        # if detects the `html` element.
        content.sub(%r{(<html[^>]+)xmlns="http://www.w3.org/1999/xhtml"}, '\1')
      else
        content
      end
    end

    def nokogiri_process(content, selectors, namespaces, klass, type, nokogiri_save_options = nil)
      # Ensure that all prefixes are strings
      namespaces = namespaces.reduce({}) { |new, (prefix, uri)| new.merge(prefix.to_s => uri) }

      doc = content =~ /<html[\s>]/ ? klass.parse(content) : klass.fragment(content)
      selector = selectors.map { |sel| "descendant-or-self::#{sel}" }.join('|')
      doc.xpath(selector, namespaces).each do |node|
        if node.name == 'comment'
          nokogiri_process_comment(node, doc, selectors, namespaces, klass, type)
        elsif path_is_relativizable?(node.content)
          node.content = relative_path_to(node.content)
        end
      end

      case type
      when :html5
        doc.to_html(save_with: nokogiri_save_options)
      else
        doc.send("to_#{type}", save_with: nokogiri_save_options)
      end
    end

    def nokogiri_process_comment(node, doc, selectors, namespaces, klass, type)
      content = node.content.dup.sub(%r{^(\s*\[.+?\]>\s*)(.+?)(\s*<!\[endif\])}m) do |_m|
        beginning = Regexp.last_match[1]
        body = Regexp.last_match[2]
        ending = Regexp.last_match[3]

        beginning + nokogiri_process(body, selectors, namespaces, klass, type) + ending
      end

      node.replace(Nokogiri::XML::Comment.new(doc, content))
    end

    def path_is_relativizable?(s)
      s.start_with?('/')
    end
  end
end
