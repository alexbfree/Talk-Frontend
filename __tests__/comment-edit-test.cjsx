jest
  .dontMock '../src/index'

describe 'CommentEdit', ->
  React = require 'react/addons'
  {findRenderedDOMComponentWithTag, scryRenderedComponentsWithType, findRenderedComponentWithType, findRenderedDOMComponentWithClass, renderIntoDocument, Simulate} = React.addons.TestUtils
  {CommentEdit} = require '../src/index'

  xit 'add tests here', ->
