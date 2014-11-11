require 'rails_helper'

RSpec.describe "connect/index.html.erb", type: :view do
  let(:connect_status) { ConnectGithubUserStatus.new(step: :request) }
  let(:user) { build(:user) }

  before do
    assign(:connect_status, connect_status)
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'renders' do
    render
  end
end
