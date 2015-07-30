Promise = require 'bluebird'

describe 'smoke tests', ->
    expect = null
    webdriver = null
    elementBy = null
    till = null

    browser = null

    before Promise.coroutine ->
        @timeout 30000

        {expect} = require 'chai'
        webdriver = require 'selenium-webdriver'
        {By: elementBy, until: till} = webdriver
        browser = new webdriver.Builder()
            .usingServer "http://#{process.env['HUB_PORT_4444_TCP_ADDR']}:#{process.env['HUB_PORT_4444_TCP_PORT']}/wd/hub"
            .forBrowser 'chrome'
            .build()

        yield browser.get "http://#{process.env['APP_PORT_8080_TCP_ADDR']}:#{process.env['APP_PORT_8080_TCP_PORT']}/"

        # wait until initial react render
        react = elementBy.css '[data-reactid]'
        yield browser.wait till.elementLocated react

    after ->
        browser.quit()

    it 'should display the home icon in the menu', Promise.coroutine ->
        homeSpan = yield browser.findElement elementBy.css '.container .sidebar.menu .item span'
        expect(yield homeSpan.getText()).to.equal 'Cache Cache'

    it 'should show the POI generator on the start page', Promise.coroutine ->
        h1 = yield browser.findElement elementBy.css 'h1'
        expect(yield h1.getText()).to.equal 'POI Generator'

