module GithubUsersHelper
  def github_user_state_label(github_user)
    state_class = case github_user.state
      when 'disabled' then 'label-danger'
      when 'unknown' then 'label-warning'
      when 'enabled' then 'label-success'
      when 'excluded' then 'label-info'
      when 'external' then 'label-info'
    end

    content_tag :span, github_user.human_state_name.capitalize, class: ['label', state_class].compact
  end
end
