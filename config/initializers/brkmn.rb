REDIRECT_DOMAIN = ENV['REDIRECT_DOMAIN'] || 'brk.mn'
escaped_redirect_domain = Regexp.escape(REDIRECT_DOMAIN)
PROTECTED_REDIRECT_REGEX = /^https?:\/\/(localhost|#{escaped_redirect_domain})/i
