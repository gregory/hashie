require 'spec_helper'

describe Hashie::Yash do
  let(:config) do
    {
      'production' => {
        'foo' => 'production_foo'
      }
    }
  end
  let(:filename) { 'database.yml' }

  describe '.load(path, parser = Extensions::Yash::YamlErbParser)' do
    let(:parser) { double(:parser) }
    let(:mash) { Hashie::Mash.new }

    subject { described_class.load(filename, parser) }

    context 'if the file exists' do
      before do
        expect(File).to receive(:file?).with(filename).and_return(true)
        expect(parser).to receive(:perform).with(filename).and_return(config)
      end

      it { is_expected.to be_a(Hashie::Mash) }

      it 'return a Mash from a file' do
        expect(subject.production).not_to be_nil
        expect(subject.production.keys).to eq config['production'].keys
        expect(subject.production.foo).to eq config['production']['foo']
      end

      it 'includes Hashie::Extensions::PrettyInspect' do
        expect(subject.class.ancestors).to include(Hashie::Extensions::PrettyInspect)
        expect(subject).to respond_to(:pretty_inspect)
      end

      it 'freeze the attribtues' do
        expect { subject.production = {} }.to raise_exception(RuntimeError, /can't modify frozen/)
      end
    end

    context 'if the fils does not exists' do
      before do
        expect(File).to receive(:file?).with(filename).and_return(false)
      end

      it 'raise an ArgumentError' do
        expect { subject }.to raise_exception(ArgumentError)
      end
    end
  end

  describe '.[](value)' do
    let(:mash) { Hashie::Mash.new }
    let(:mash2) { Hashie::Mash.new }

    subject { described_class[filename] }

    before do
      described_class.instance_variable_set('@_mashes', nil) # clean the cash
    end

    it 'cache the loaded yml file' do
      expect(described_class).to receive(:load).once.with(filename).and_return(mash)
      expect(described_class).to receive(:load).once.with("#{filename}+1").and_return(mash2)

      3.times do
        expect(subject).to be_a(Hashie::Mash)
        expect(described_class["#{filename}+1"]).to be_a(Hashie::Mash)
      end

      expect(subject.object_id).to eq subject.object_id
    end

  end

  describe '#extended(klass)' do
    let(:filename) { 'database.yml' }
    let(:yash) { described_class.new(filename) }
    let(:klass) { Class.new.extend yash }
    let(:mash) { double(:mash) }

    before do
      expect(described_class).to receive(:[]).with(filename).and_return(mash)
    end

    it 'defines a settings method on the klass class that extends the module' do
      expect(klass).to respond_to(:settings)
      expect(klass.settings).to eq mash
    end

    context 'when a settings_method_name is set' do
      let(:settings_method_name) { 'config' }
      let(:yash) { described_class.new(filename, settings_method_name: settings_method_name) }

      it 'defines a settings method on the klass class that extends the module' do
        expect(klass).to respond_to(settings_method_name.to_sym)
        expect(klass.send(settings_method_name.to_sym)).to eq mash
      end
    end
  end
end
