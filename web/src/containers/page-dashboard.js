import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

import {
    removeCallout,
} from '../actions'


import Dashboard from '../components/dashboard'
import Map from '../components/map';
import MapControls from '../mapcontrols';

class PageDashboard extends Component {

    render() {
        return (
            <div>
                <Map/>
                <MapControls.container/>
            </div>
        )
    }
}

PageDashboard.propTypes = {
    url: PropTypes.string.isRequired,
    callouts: PropTypes.array.isRequired,
}

function mapStateToProps(state) {
    return {
        url: state.routing.location.pathname,
        callouts: state.notifications.callouts,
    }
}

export default connect(mapStateToProps, {
    removeCallout,
})(PageDashboard)
