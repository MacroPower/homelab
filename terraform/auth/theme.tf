locals {
    color_foreground = "#abb2bf"
    color_background = "#23272e"

    color0  = "#282c34"
    color1  = "#e06c75"
    color2  = "#98c379"
    color3  = "#e5c07b"
    color4  = "#61afef"
    color5  = "#be5046"
    color6  = "#56b6c2"
    color7  = "#979eab"
    color8  = "#393e48"
    color9  = "#d19a66"
    color10 = "#56b6c2"
    color11 = "#e5c07b"
    color12 = "#61afef"
    color13 = "#be5046"
    color14 = "#56b6c2"
    color15 = "#abb2bf"
}

# https://registry.terraform.io/providers/auth0/auth0/latest/docs/resources/branding_theme
resource "auth0_branding_theme" "atom_one_dark" {
  borders {
    button_border_radius = 3
    button_border_weight = 1
    buttons_style        = "rounded"
    input_border_radius  = 3
    input_border_weight  = 1
    inputs_style         = "rounded"
    show_widget_shadow   = true
    widget_border_weight = 0
    widget_corner_radius = 5
  }

  colors {
    # Text colors
    body_text = local.color_foreground
    header    = local.color_foreground
    icons     = local.color7

    # Input field colors
    input_background          = local.color0
    input_border              = local.color8
    input_filled_text         = local.color_foreground
    input_labels_placeholders = local.color7

    # Interactive elements
    base_focus_color         = local.color4
    base_hover_color         = local.color4
    links_focused_components = local.color4
    primary_button           = local.color2
    primary_button_label     = local.color0
    secondary_button_border  = local.color8
    secondary_button_label   = local.color_foreground

    # Status colors
    error   = local.color1
    success = local.color2

    # Widget colors
    widget_background = local.color0
    widget_border     = local.color8

    captcha_widget_theme = "dark"
  }

  fonts {
    # https://github.com/mozilla/Fira/
    font_url = "https://jacobcolvin.com/fonts/FiraSans-Regular.woff2"

    links_style         = "normal"
    reference_text_size = 16.0

    body_text { bold = false }
    buttons_text { bold = false }
    input_labels { bold = false }
    links { bold = false }
    title { bold = false }
    subtitle { bold = false }
  }

  page_background {
    # https://github.com/Narmis-E/onedark-wallpapers/
    background_image_url = "https://jacobcolvin.com/img/od_neon_warm_blur.jpg"
    background_color     = local.color_background
    page_layout          = "center"
  }

  widget {
    header_text_alignment = "center"
    logo_position         = "none"
    logo_url              = ""
  }
}
