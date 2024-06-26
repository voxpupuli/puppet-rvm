# frozen_string_literal: true

require 'spec_helper'

describe 'rvm_alias' do
  let(:title) { '2.0' }
  let(:params) { { target_ruby: '2.0-384' } }

  context 'when using default parameters', :compile do
    it { is_expected.to contain_rvm_alias('2.0').with_target_ruby('2.0-384') }
  end
end
