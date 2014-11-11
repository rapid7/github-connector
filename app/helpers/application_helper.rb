module ApplicationHelper
  def current_user_path
    url_for controller: :users, action: :show, id: current_user ? current_user.username : nil
  end

  def jumbotron(&block)
    content_for(:jumbotron, &block)
  end

  def settings
    Rails.application.settings
  end

  def title(page_title)
    content_for(:title, page_title.to_s)
  end

  def nav_section(nav_section)
    content_for(:nav_section, nav_section)
  end

  def format_time(time)
    return nil unless time
    content_tag(:span, time.to_s, data: { time: time.utc.iso8601 })
  end
end
