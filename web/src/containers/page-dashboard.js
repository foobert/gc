import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

import {
    removeCallout,
    toggleUserFilter,
    addUserFilter,
    removeUserFilter,
} from '../actions'

import Dashboard from '../components/dashboard'
import Map from '../components/map';
import MapControls from '../components/mapcontrols';

class PageDashboard extends Component {

    render() {
        return (
            <div>
                <Map/>
                <MapControls
            userFilterEntries={this.props.userFilterEntries}
            userFilterExpanded={this.props.userFilterExpanded}
            onAddUserFilter={this.props.addUserFilter}
            onRemoveUserFilter={this.props.removeUserFilter}
            onToggleUserFilter={this.props.toggleUserFilter}/>
                </div>
        )
    }
}

PageDashboard.propTypes = {
    url: PropTypes.string.isRequired,
    callouts: PropTypes.array.isRequired,
    removeCallout: PropTypes.func.isRequired,
}

function mapStateToProps(state) {
    return {
        url: state.routing.location.pathname,
        callouts: state.notifications.callouts,
        userFilterExpanded: state.userFilters.expanded,
        userFilterEntries: state.userFilters.filtered,
    }
}

export default connect(mapStateToProps, {
    removeCallout,
    toggleUserFilter,
    addUserFilter,
    removeUserFilter,
})(PageDashboard)
