# frozen_string_literal: true

shared_examples 'compile', compile: true do
  it { is_expected.to compile.with_all_deps }
end
