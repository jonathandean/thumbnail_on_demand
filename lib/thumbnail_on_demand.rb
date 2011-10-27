Paperclip::Attachment.class_eval do

  IMAGE_EXTENSIONS = [".jpg", ".jpeg", ".jpe", ".png", ".gif", ".bmp"]

  # Creates a thumbnail if it doesn't already exist and not if it does. Either way, it returns the URL to the thumbnail
  #
  # @param [Symbol] style A symbol telling which style to use (from the :on_demand_styles option)
  # @param [Symbol] from_style A symbol telling which paperclip style to create the thumbnail from.
  #   If either nil or :original it will use the originally uploaded image (default_style)
  # @param [Object] options An object of url options, same as the second param in paperclip's url method
  # @return [String] The URL to the thumbnail
  # TODO check to be sure the attachment is an image (thumbnailable)?
  # TODO S3/other storage support
  # TODO should remove thumbnails when removing the orginal paperclip attachment
  # TODO would be nice to have the ability to crop default_url according to the requested style
  def thumbnail(style_name, from_style = nil, options = {})
    options = handle_url_options(options)
    thumbnail_url = interpolate(most_appropriate_url, style_name)
    thumbnail_path = original_filename.nil? ? nil : interpolate(@options.path, style_name)
    # Since this add-on only supports images, make sure thumbnail_path is going to save with an image file extension.
    # Otherwise it will save an image with the extension of the original file, which will be wrong if the original isn't an image.
    # We do this to support thumbnailing of other attachment types, such as video (see README.rdoc for an example).
    # TODO we shouldn't just assume jpg format when picking an image extension to add
    unless IMAGE_EXTENSIONS.include? File.extname(thumbnail_path)
      thumbnail_path = "#{thumbnail_path}#{IMAGE_EXTENSIONS.first}"
      thumbnail_url = "#{thumbnail_url}#{IMAGE_EXTENSIONS.first}"
    end
    # Initalize original_path using the default_style (original attachment)
    original_path = original_filename.nil? ? nil : interpolate(@options.path, default_style)
    # We can optionally create the thumbnail from another (non on-demand) style and set original_path to that instead
    # TODO test to be sure from_style is in @options.styles
    # TODO if from_style isn't found in @options.styles also check @options.raw_options[:on_demand_styles] and attempt to use it from there
    unless from_style.nil? || from_style == :original
      # get the path to the thumbnail
      from_style_path = original_filename.nil? ? nil : interpolate(@options.path, from_style)
      # only try to use it if that file exists
      if File.exists? from_style_path
        original_path = from_style_path
      end
    end

    # If thumbnail_path or original_filename is nil then we have no image so we'll let it return the default_url
    unless thumbnail_path.nil? || original_filename.nil? || !File.exists?(original_path)
      # If the file doesn't exist we need to make it first
      unless File.exists?(thumbnail_path)
        begin
          # TODO should create this on init of paperclip somehow and not here?
          style = Paperclip::Style.new(style_name, @options.raw_options[:on_demand_styles][:"#{style_name}"], self)
          original_file = File.new(original_path)
          if original_file && original_file.size > 0
            temp_thumbnail = Paperclip.processor(:thumbnail).make(original_file, style.processor_options, self)
            original_file.close
            if temp_thumbnail && temp_thumbnail.size > 0
              # If the folder doesn't exist, make it
              FileUtils.mkdir_p(File.dirname(thumbnail_path))
              # Save the thumnail to thumbnail_path
              FileUtils.cp(temp_thumbnail.path, thumbnail_path)
              # Close and unlink the tempfile
              temp_thumbnail.close!
            else
              thumbnail_url = interpolate(default_url, style_name)
            end
          else
            thumbnail_url = interpolate(default_url, style_name)
          end
        rescue
          thumbnail_url = interpolate(default_url, style_name)
        end
      end
    else
      thumbnail_url = interpolate(default_url, style_name)
    end

    thumbnail_url = url_timestamp(thumbnail_url) if options[:timestamp]
    thumbnail_url = escape_url(thumbnail_url)    if options[:escape]
    thumbnail_url
  end

end

class ThumbnailOnDemandError < StandardError; end