require 'rails_helper'

describe ConnectGithubUserJob do
  subject(:job) { ConnectGithubUserJob.new }
  subject(:status) { ConnectGithubUserStatus.new(step: :grant) }

  let(:oauth) { double('oauth', auth_code: double(get_token: oauth_token)) }
  let(:oauth_token) { double('oauth_token', token: 'footoken') }
  let(:octokit) { double('octokit', user: ghuser) }
  let(:ghuser) { double(id: 1337, login: 'githubuser') }
  let(:github_user) { build(:github_user, id: 1337) }

  before do
    allow(job).to receive(:oauth_client).and_return(oauth)
    allow(GithubUser).to receive(:find_or_initialize_by).and_return(github_user)
    allow(github_user).to receive(:sync!) { github_user.save! }
    allow(github_user).to receive(:add_to_organizations).and_return(true)
    allow(github_user).to receive(:do_enable)
    allow(github_user).to receive(:do_disable)
    allow(github_user).to receive(:do_notify_disabled)
    allow(Octokit::Client).to receive(:new).and_return(octokit)
  end

  it 'validates OAuth code' do
    expect(job).to receive(:oauth_process_auth_code).and_return(github_user)
    job.perform(status)
    expect(status.status).to eq(:complete)
  end

  it 'adds user to organzations' do
    expect(github_user).to receive(:add_to_organizations).and_return(true)
    job.perform(status)
    expect(status.status).to eq(:complete)
  end

  it 'enables the user' do
    expect(github_user).to receive(:enable)
    job.perform(status)
    expect(status.status).to eq(:complete)
  end

  it 'stores error if OAuth fails' do
    oauth_response = double.as_null_object
    expect(job).to receive(:oauth_process_auth_code).and_raise(OAuth2::Error.new(oauth_response))
    job.perform(status)
    expect(status.status).to eq(:error)
  end

  it 'stores error if add_to_organizations fails' do
    expect(github_user).to receive(:add_to_organizations).and_return(false)
    job.perform(status)
    expect(status.status).to eq(:error)
  end

  it 'stores error if unexpected error occurs' do
    allow(github_user).to receive(:add_to_organizations).and_raise('fooerror')
    job.perform(status)
    expect(status.status).to eq(:error)
  end
end
