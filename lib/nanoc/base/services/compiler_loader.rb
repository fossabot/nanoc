# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class CompilerLoader
    def load(site, action_provider: nil, changes: nil)
      action_sequence_store = Nanoc::Int::ActionSequenceStore.new(site: site)

      dependency_store =
        Nanoc::Int::DependencyStore.new(site.items, site.layouts, site.config, site: site)

      objects = site.items.to_a + site.layouts.to_a + site.code_snippets + [site.config]

      checksum_store =
        Nanoc::Int::ChecksumStore.new(site: site, objects: objects)

      action_provider ||= Nanoc::Int::ActionProvider.named(:rule_dsl).for(site)

      outdatedness_store =
        Nanoc::Int::OutdatednessStore.new(site: site)

      compiled_content_cache =
        Nanoc::Int::CompiledContentCache.new(
          site: site,
          items: site.items,
        )

      params = {
        changes: changes,
        compiled_content_cache: compiled_content_cache,
        checksum_store: checksum_store,
        action_sequence_store: action_sequence_store,
        dependency_store: dependency_store,
        action_provider: action_provider,
        outdatedness_store: outdatedness_store,
      }

      Nanoc::Int::Compiler.new(site, params)
    end
  end
end
