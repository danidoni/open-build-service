require 'rails_helper'

RSpec.describe Workflows::Filter, type: :service do
  # architecture
          # only
              # matching
              # not matching
          # ignore
              # matching
              # not matching

      # repositories
          # only
              # matching
              # not matching
          # ignore
              # matching
              # not matching

  describe '#match?' do
    subject { described_class.new(filters: workflow_filters).match? }
    let(:event) { Event::BuildSuccess.create(project: project.name, package: package.name, repository: 'openSUSE_Tumbleweed', arch: 'x86_64', reason: 'foo') }

    context 'architectures' do
      context 'ignore' do
        let(:workflow_filters) do
          {}
        end

      end

      context 'only' do
        let(:workflow_filters) do
          {}
        end
      end
    end

    context 'repositories' do

      context 'ignore' do
        let(:workflow_filters) do
          {}
        end
      end

      context 'only' do
        let(:workflow_filters) do
          {}
        end
      end
    end
  end
end
