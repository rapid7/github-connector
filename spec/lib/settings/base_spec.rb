require 'rails_helper'
require 'settings/base'

describe Settings::Base do

  class TestSettings < ::Settings::Base
    setting :myname
    setting :mynumber, type: :integer
    setting :myfloat, type: :float
    setting :mybool, type: :boolean
    setting :mydate, type: :datetime
    setting :myarray, type: :array
    setting :myhash, type: :hash
  end

  subject(:settings) { TestSettings.new }

  describe '#dirty?' do
    subject(:settings) { TestSettings.new.disconnect }

    it 'tracks dirty attributes' do
      settings.myname = 'foobar'
      expect(settings).to be_dirty(:myname)
    end

    it 'tracks clean attributes' do
      settings.myname = 'foobar'
      expect(settings).to_not be_dirty(:mynumber)
    end
  end

  describe '#disconnect' do
    it 'returns a cloned object' do
      disconnected = settings.disconnect
      expect(disconnected).to be_disconnected
      expect(disconnected).to_not eq(settings)
    end

    it 'does not disconnect the current object' do
      settings.disconnect
      expect(settings).to_not be_disconnected
    end
  end

  describe '#hash_for' do
    before do
      settings.myname = 'foobar'
      settings.mynumber = 100
    end

    it 'returns a hash for the given keys' do
      expect(settings.hash_for([:myname])).to eq({myname: 'foobar'})
    end

    it 'returns an empty hash if no keys are given' do
      expect(settings.hash_for([])).to eq({})
    end
  end

  describe '#keys' do
    it 'returns all defined settings' do
      expect(settings.keys).to eq(%i(myname mynumber myfloat mybool mydate myarray myhash))
    end
  end

  describe '#load' do
    subject(:settings) { TestSettings.new.disconnect }

    before do
      Setting.create!(key: 'myname', value: 'foobar')
      Setting.create!(key: 'mynumber', value: '100')
      Setting.create!(key: 'myfloat', value: '100.0')
      Setting.create!(key: 'mybool', value: 'true')
      Setting.create!(key: 'mydate', value: '2014-06-30')
      Setting.create!(key: 'myarray', value: ['foo', 'bar'].to_json)
      Setting.create!(key: 'myhash', value: {'foo' => 'bar'}.to_json)
    end

    it 'loads all settings' do
      settings.load
      expect(settings.myname).to eq('foobar')
      expect(settings.mynumber).to eq(100)
    end

    it 'loads a subset of settings' do
      settings.load(:myname)
      expect(settings.myname).to eq('foobar')
      expect(settings.mynumber).to be_nil
    end

    it 'loads array settings' do
      settings.load(:myarray)
      expect(settings.myarray).to eq(['foo', 'bar'])
    end

    it 'loads hash settings' do
      settings.load(:myhash)
      expect(settings.myhash).to eq('foo' => 'bar')
    end
  end

  describe '#save' do
    subject(:settings) { TestSettings.new.disconnect }

    it 'saves settings' do
      settings.myname = 'foobar'
      settings.mynumber = 100
      settings.myfloat = 100.1
      settings.mybool = false
      settings.mydate = Time.now
      settings.save
      expect(Setting.count).to eq(5)
    end

    it 'only saves dirty settings' do
      Setting.create!(key: 'myname', value: 'foobar')
      Setting.create!(key: 'mynumber', value: '100')
      settings.load
      settings.myname = 'foo'
      expect_any_instance_of(Setting).to receive(:save!).exactly(1).times.and_call_original
      settings.save
    end

    it 'saves array settings with JSON' do
      settings.myarray = ['foo', 'bar']
      settings.save
      setting = Setting.find_by_key('myarray')
      expect(setting.value).to eq(['foo', 'bar'].to_json)
    end

    it 'saves hash settings with JSON' do
      settings.myhash = {'foo' => 'bar'}
      settings.save
      setting = Setting.find_by_key('myhash')
      expect(setting.value).to eq({'foo' => 'bar'}.to_json)
    end
  end

  describe '#to_h' do
    before do
      settings.myname = 'foobar'
      settings.mynumber = 100
    end

    it 'returns a hash with all settings' do
      expect(settings.to_h).to eq(myname: 'foobar', mynumber: 100)
    end
  end

  describe '#with_disconnected' do
    it 'disconnects settings' do
      expect(Rails.application.settings).to_not be_disconnected
      Rails.application.settings.with_disconnected do
        expect(Rails.application.settings).to be_disconnected
      end
    end

    it 'restores disconnected state' do
      expect(Rails.application.settings).to_not be_disconnected
      Rails.application.settings.with_disconnected {}
      expect(Rails.application.settings).to_not be_disconnected
    end

    it 'can be nested' do
      expect(Rails.application.settings).to_not be_disconnected
      Rails.application.settings.with_disconnected do |settings|
        settings.with_disconnected {}
        expect(Rails.application.settings).to be_disconnected
      end
      expect(Rails.application.settings).to_not be_disconnected
    end
  end

  context 'when connected' do
    before do
      Setting.create!(key: 'myname', value: 'foobar')
    end

    it 'loads automatically' do
      expect(settings.myname).to eq('foobar')
    end

    it 'saves automatically' do
      settings.mynumber = 100
      expect(Setting.where(key: :mynumber).first.value).to eq('100')
    end
  end

  context 'when disconnected' do
    subject(:settings) { TestSettings.new.disconnect }

    before do
      Setting.create!(key: 'myname', value: 'foobar')
    end

    it 'does not load automatically' do
      expect(settings.myname).to be_nil
    end

    it 'does not save automatically' do
      settings.mynumber = 100
      expect(Setting.where(key: :mynumber)).to be_empty
    end
  end

end
