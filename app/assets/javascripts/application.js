// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery.form
//= require_tree .

$.extend({
  rootPath: function(){
    return '/';
  },
  updateUrlList:function(){
    if($('#url_list').length > 0){
      $.ajax({
        method: 'get',
        url: $.rootPath() + 'urls/url_list',
      data: {filter: $('#filter').val()},
      dataType: 'html',
      success: function(html){
        $('#url_list').html(html);
        if($.cookie('hide_filter_control') == 'hide'){
          $('#filters').hide();
          $('#filter_control span').html('Show filter');
        }
      }
    });
  }
},
  observeListPagination: function(){
    $('.pagination a').live('click',function(e){
      var paginationTarget = $(this).closest('#url_list');
      e.preventDefault();
      $.ajax({
        type: 'GET',
        url: $(this).attr('href'),
        dataType: 'html',
        success: function(html){
          $(paginationTarget).html(html);
          if($.cookie('hide_filter_control') == 'hide'){
            $('#filters').hide();
            $('#filter_control span').html('Show filter');
          }
        }
      });
    });
  }
});

$(document).ready(function(){
  $('#url_to').focus();
  // The line below looks odd, but what it does is set the cursor focus to the end of the line in the url_to field.
  $('#url_to').val($('#url_to').val());
  $('#new_url').ajaxForm({
    dataType: 'html',
    success: function(html){
      $('#new_url .messages').show().html('<span class="notice">' + html + '</span>');
      $('#url_to').val('');
      $('#url_shortened').val('');
      $('#url_to').focus();
      $.updateUrlList();
    },
    error: function(e){
      $('#new_url .messages').show().html('<span class="error">' + e.responseText + '</span>');
      $('#url_to').focus();
    }
  });

  $('#filter_control').live({
    click: function(e){
      e.preventDefault();
      var filter_viz = $.cookie('hide_filter_control');
      if(filter_viz == undefined){
        console.log('hide');
        $('#filters').hide('slow');
        $('#filter_control span').html('Show filter');
        $.cookie('hide_filter_control','hide');
      } else {
        console.log('show');
        $('#filters').show('slow');
        $('#filter_control span').html('Hide filter');
        $.cookie('hide_filter_control',null);
      }
    }
  });

  $('#filter').live({
    keydown: function(e){
      if(e.which == 13){
        e.preventDefault();
        $.updateUrlList();
      }
    }
  });

  $('#apply_filter').live({
    click: function(e){
      e.preventDefault();
      $.updateUrlList();
    }
  });

  $('#clear_filter').live({
    click: function(e){
      e.preventDefault();
      $('#filter').val('');
      $.updateUrlList();
    }
  });

  $.updateUrlList();
  $.observeListPagination();
});
