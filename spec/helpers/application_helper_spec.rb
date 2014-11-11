require 'rails_helper'

describe ApplicationHelper do
  describe '#format_time' do
    it 'adds data-time attribute' do
      html = format_time(Time.now)
      expect(html).to include('data-time')
    end
  end
end
