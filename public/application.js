$(document).ready(function() {

  player_hits();
  player_stays();
  dealer_hits();

});

function player_hits() {
  $(document).on('click', '#hit-form input', function() {
    $.ajax({
      url: '/game/player/hit',
    type: 'POST'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function player_stays() {
  $(document).on('click', '#stay-form input', function() {
    $.ajax({
      url: '/game/player/stay',
    type: 'POST'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function dealer_hits() {
  $(document).on('click', '#dealer-hit-form input', function() {
    $.ajax({
      url: '/game/dealer/hit',
    type: 'POST'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });
}
