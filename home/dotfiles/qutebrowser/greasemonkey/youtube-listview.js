// ==UserScript==
// @name         YouTube list view
// @description  Forces list view on subscriptions and other grid pages
// @include      https://www.youtube.com/*
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  // Prefer list view: set fewer columns on grid pages and use compact layout
  function injectListStyles() {
    const id = 'yt-listview-style';
    if (document.getElementById(id)) return;
    const s = document.createElement('style');
    s.id = id;
    s.textContent = `
      /* Subscriptions / home: force single-column compact layout */
      ytd-browse[page-subtype="subscriptions"] ytd-rich-grid-renderer,
      ytd-browse[page-subtype="home"] ytd-rich-grid-renderer {
        --ytd-rich-grid-items-per-row: 1 !important;
        --ytd-rich-grid-posts-per-row: 1 !important;
      }

      ytd-browse[page-subtype="subscriptions"] ytd-rich-item-renderer,
      ytd-browse[page-subtype="home"] ytd-rich-item-renderer {
        max-width: 100% !important;
      }

      /* Make each card horizontal (thumbnail left, info right) */
      ytd-browse[page-subtype="subscriptions"] ytd-rich-grid-media,
      ytd-browse[page-subtype="home"] ytd-rich-grid-media {
        flex-direction: row !important;
        align-items:    flex-start !important;
      }

      ytd-browse[page-subtype="subscriptions"] #thumbnail.ytd-rich-grid-media,
      ytd-browse[page-subtype="home"] #thumbnail.ytd-rich-grid-media {
        width:      246px !important;
        min-width:  246px !important;
        max-width:  246px !important;
        margin-right: 12px !important;
      }

      ytd-browse[page-subtype="subscriptions"] #details.ytd-rich-grid-media,
      ytd-browse[page-subtype="home"] #details.ytd-rich-grid-media {
        flex: 1 !important;
      }
    `;
    document.head.appendChild(s);
  }

  // YouTube is a SPA — re-run on navigation
  const observer = new MutationObserver(injectListStyles);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  injectListStyles();
})();
