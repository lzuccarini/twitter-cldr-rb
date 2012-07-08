# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'spec_helper'

include TwitterCldr::Collation

describe 'Unicode collation tailoring' do

  before(:each) do
    stub(Collator).default_fce_trie { TrieBuilder.parse_trie(fractional_uca_short_stub) }
    stub(TwitterCldr::Normalization::NFD).normalize_code_points { |code_points| code_points }
    stub(TwitterCldr).get_resource(:collation, :tailoring, locale) { YAML.load(tailoring_resource_stub) }
  end

  let(:locale)            { :some_locale }
  let(:default_collator)  { Collator.new }
  let(:tailored_collator) { Collator.new(locale) }

  describe 'tailoring rules support' do
    it 'tailored collation elements are used' do
      default_collator.get_collation_elements(%w[0490]).should  == [[0x5C1A, 5, 0x93], [0, 0xDBB9, 9]]
      tailored_collator.get_collation_elements(%w[0490]).should == [[0x5C1B, 5, 0x86]]

      default_collator.get_collation_elements(%w[0491]).should  == [[0x5C1A, 5, 9], [0, 0xDBB9, 9]]
      tailored_collator.get_collation_elements(%w[0491]).should == [[0x5C1B, 5, 5]]
    end

    it 'original contractions for tailored elements are applied' do
      default_collator.get_collation_elements(%w[0491 0306]).should  == [[0x5C, 0xDB, 9]]
      tailored_collator.get_collation_elements(%w[0491 0306]).should == [[0x5C, 0xDB, 9]]
    end
  end

  describe 'contractions suppressing support' do
    it 'suppressed contractions are ignored' do
      default_collator.get_collation_elements(%w[041A 0301]).should  == [[0x5CCC, 5, 0x8F]]
      tailored_collator.get_collation_elements(%w[041A 0301]).should == [[0x5C6C, 5, 0x8F], [0, 0x8D, 5]]
    end

    it 'non-suppressed contractions are used' do
      default_collator.get_collation_elements(%w[0415 0306]).should  == [[0x5C36, 5, 0x8F]]
      tailored_collator.get_collation_elements(%w[0415 0306]).should == [[0x5C36, 5, 0x8F]]
    end
  end

  let(:fractional_uca_short_stub) do
<<END
# collation elements from default FCE table
0301; [, 8D, 05]
0306; [, 91, 05]
041A; [5C 6C, 05, 8F] # К
0413; [5C 1A, 05, 8F] # Г
0415; [5C 34, 05, 8F] # Е

# tailored (in UK locale) with "Г < ґ <<< Ґ"
0491; [5C 1A, 05, 09][, DB B9, 09] # ґ
0490; [5C 1A, 05, 93][, DB B9, 09] # Ґ

# contraction for a tailored collation element
0491 0306; [5C, DB, 09] # ґ̆

# contractions suppressed in tailoring (for RU locale)
041A 0301; [5C CC, 05, 8F] # Ќ
0413 0301; [5C 30, 05, 8F] # Ѓ

# contractions non-suppressed in tailoring
0415 0306; [5C 36, 05, 8F] # Ӗ
END
  end

  let(:tailoring_resource_stub) do
<<END
---
:tailored_table: ! '0491; [5C1B, 5, 5]

  0490; [5C1B, 5, 86]'
:suppressed_contractions: ГК
...
END
  end

end
