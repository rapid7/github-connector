class ConnectGithubUserStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :github_user

  def step_complete?(step)
    steps_completed.include?(step)
  end

  def step_disabled?(step)
    steps_disabled.include?(step)
  end

  def step_error?(step)
    self.step == step && status == :error
  end

  def in_progress?
    %i(queued running).include?(status)
  end

  def complete?
    %i(complete).include?(status)
  end

  def status
    status = read_attribute(:status)
    status ? status.to_sym : nil
  end

  def step
    step = read_attribute(:step)
    step ? step.to_sym : nil
  end

  def steps
    %i(create request grant add teams)
  end

  def steps_completed
    if step == :request && !github_user_id
      []
    elsif status == :complete
      steps
    else
      steps.first(step_index)
    end
  end

  def steps_disabled
    steps.last(steps.count - step_index - 1)
  end

  private

  def step_index
    steps.index(step)
  end
end
