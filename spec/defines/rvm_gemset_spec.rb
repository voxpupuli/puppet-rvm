# frozen_string_literal: true

require 'spec_helper'

describe 'rvm_gemset' do
  let(:title) { 'ruby-1.9@myproject' }

  context 'when using default parameters', :compile do
    it { is_expected.to contain_rvm_gemset('ruby-1.9@myproject').with_ruby_version('ruby-1.9') }
  end

  context 'when setting ruby_version', :compile do
    let(:params) { { ruby_version: '1.9' } }

    it { is_expected.to contain_rvm_gemset('ruby-1.9@myproject').with_ruby_version('1.9') }
  end
end
