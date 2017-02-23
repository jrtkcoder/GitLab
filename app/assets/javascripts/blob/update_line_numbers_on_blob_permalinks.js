
const updateLineNumbersOnBlobPermalinks = (linksToUpdate) => {
  const hash = gl.utils.getLocationHash();
  if (hash && (/^L[0-9]+/).test(hash)) {
    const hashUrlString = `#${hash}`;

    [].concat(Array.prototype.slice.call(linksToUpdate)).forEach((permalinkButton) => {
      const baseHref = permalinkButton.getAttribute('data-original-href') || (() => {
        const href = permalinkButton.getAttribute('href');
        permalinkButton.setAttribute('data-original-href', href);
        return href;
      })();
      permalinkButton.setAttribute('href', `${baseHref}${hashUrlString}`);
    });
  }
};

export default updateLineNumbersOnBlobPermalinks;
