require 'rails_helper'

describe ConnectGithubUserStatus do
  subject(:status) { described_class.new(step: :request, status: :running) }
  let(:step) { :request }

  it 'computes completed steps' do
    expect(status.step_complete?(:add)).to eq(false)
    expect(status.steps_completed).to be_empty
    status.step = :add
    expect(status.step_complete?(:request)).to eq(true)
    status.status = :complete
    expect(status.step_complete?(:teams)).to eq(true)
  end

  it 'computes disabled steps' do
    expect(status.step_disabled?(:grant)).to eq(true)
    expect(status.step_disabled?(:create)).to eq(false)
  end

  it 'computes in progress status' do
    expect(status.in_progress?).to eq(true)
    status.status = :complete
    expect(status.in_progress?).to eq(false)
  end

  it 'computes complete status' do
    expect(status.complete?).to eq(false)
    status.status = :complete
    expect(status.complete?).to eq(true)
  end

  it 'computes error steps' do
    expect(status.step_error?(:request)).to eq(false)
    status.status = :error
    expect(status.step_error?(:request)).to eq(true)
    expect(status.step_error?(:create)).to eq(false)
  end
end
