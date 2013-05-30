module DietsHelper
  def diet_logged_at(diet)
    return '' unless diet.present?
    diet.created_at.strftime('%b %d, %Y %H:%M:%S %:z')
  end

  def diet_photo(diet, style=:medium)
    if diet.photo.blank?
      image_tag @diet.photo.url, size: '250x150'
    else
      image_tag @diet.photo.url(style)
    end
  end

end
