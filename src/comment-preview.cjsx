React = require 'react'

module?.exports = React.createClass
  displayName: 'TalkCommentPreview'

  formattedPreviewContent: (str) ->
    (str + ' ').replace(/@user:(\S+) /, "<a href='http://www.zooniverse.org/user/$1'>$1</a>")

  render: ->
    <div className='talk-comment-preview'>
      <h1>Preview</h1>
      <div className='talk-comment-preview-content' dangerouslySetInnerHTML={__html: @formattedPreviewContent(@props.content)}></div>
    </div>
