$.extend
  rootPath: ()->
    return '/'

  updateUrlList: ()->
    if $('#url_list').length > 0
      $.ajax
        type: 'GET'
        url: $.rootPath() + 'urls/url_list'
        data: 
          filter: $('#filter').val()
        dataType: 'html'
        success: (html)->
          $('#url_list').html(html)
          if $.cookie('hide_filter_control') == 'hide'
            $('#filters').hide()
            $('#filter_control span').html('Show filter')

  observeListPagination: ()->
    $('.pagination a').live
      click: (e)->
        paginationTarget = $(this).closest('#url_list')
        e.preventDefault();
        $.ajax
          type: 'GET',
          url: $(this).attr('href')
          dataType: 'html'
          success: (html)->
            $(paginationTarget).html(html)
            if $.cookie('hide_filter_control') == 'hide'
              $('#filters').hide()
              $('#filter_control span').html('Show filter')

$(document).ready ()->
  $('#url_to').focus()
  # The line below looks odd, but what it does is set the cursor focus to the end of the line in the url_to field.

  $('#url_to').val($('#url_to').val())

  $('#new_url').ajaxForm
    dataType: 'html'
    success: (html)->
      $('#new_url .messages').show().html('<span class="notice">' + html + '</span>')
      $('#url_to').val('')
      $('#url_shortened').val('')
      $('#url_to').focus()
      $.updateUrlList()
    error: (e)->
      $('#new_url .messages').show().html('<span class="error">' + e.responseText + '</span>')
      $('#url_to').focus()

  $('#filter_control').live
    click: (e)->
      e.preventDefault()
      filter_viz = $.cookie('hide_filter_control')
      if filter_viz != 'hide' 
        $('#filters').hide('slow')
        $('#filter_control span').html('Show Filter')
        $.cookie('hide_filter_control','hide')
      else
        $('#filters').show('slow')
        $('#filter_control span').html('Hide Filter')
        $.cookie('hide_filter_control',undefined)

  $('#filter').live
    keydown: (e)->
      if e.which == 13
        e.preventDefault()
        $.updateUrlList()
  
  $('#apply_filter').live
    click: (e)->
      e.preventDefault()
      $.updateUrlList()

  $('#clear_filter').live
    click: (e)->
      e.preventDefault()
      $('#filter').val('')
      $.updateUrlList()

  $.updateUrlList()
  $.observeListPagination()
