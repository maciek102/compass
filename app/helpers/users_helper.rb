module UsersHelper
  def user_display_image(user)
    if user.avatar.attached?
      image_tag user.avatar_url(:thumb)
    else
      content_tag :div, user.name.first.upcase, class: "avatar-placeholder"
    end
  end
end
