$(document).ready(function() {

  $(document).on('click', '#hit-form input', function() {
    $.ajax({
      url: '/game/player/hit',
    type: 'POST'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#stay-form input', function() {
    $.ajax({
      url: '/game/player/stay',
    type: 'POST'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#dealer-hit-form input', function() {
    $.ajax({
      url: '/game/dealer/hit',
    type: 'POST'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

});
