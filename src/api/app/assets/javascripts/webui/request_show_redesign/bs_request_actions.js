// JavaScript code for the new view under request_show_redesign

function appendAnchorToHref(href) {
  var HASH_PREFIX = 'tab-pane-';
  var hashRegexp = new RegExp("#" + HASH_PREFIX + ".+");

  if (document.location.hash.search('#diff_') !== -1 && href.search('#') === -1) {
    href = href + '#' + HASH_PREFIX + 'changes';
  }
  else if (href.search('#') === -1) {
    href = href + document.location.hash;
  }
  else if (document.location.hash.search('#diff_') === -1) {
    href = href.replace(hashRegexp, document.location.hash);
  }
  return href;
}

