# frozen_string_literal: true

class ThemeController < ApplicationController
  def toggle_mode
    current_mode = cookies[:viewing_mode] == 'classic' ? 'modern' : 'classic'
    cookies[:viewing_mode] = { value: current_mode, expires: 1.year.from_now }

    respond_to do |format|
      format.html { render 'toggle_mode' }
    end
  end
end
