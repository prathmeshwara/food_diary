module DietsHelper
  def diet_logged_at(diet)
    return '' unless diet.present?
    diet.created_at.strftime('%b %d, %Y %H:%M:%S %:z')
  end
end
