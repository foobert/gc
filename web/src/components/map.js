import 'leaflet/dist/leaflet.css';
//require '../../css/map.css'

import React, { Component } from 'react';
import L from 'leaflet';
import _ from 'lodash';

//Popup = require './map/popup.cjsx'

export default class Map extends Component {
    static defaultProps = {
        zoom: 5,
        center: {lat: 51, lon: 12},
    }

    static propTypes = {
        onMapChange: React.PropTypes.func,
        markers: React.PropTypes.array, // TODO define shape of geocaches?
        center: React.PropTypes.shape({lat: React.PropTypes.number, lon: React.PropTypes.number}),
        zoom: React.PropTypes.number,
    }

    componentDidMount() {
        this.icons = _.keyBy([2, 3, 4, 5, 6, 8, 11, 13, 137, 453, 1858], (x) => this.createIcon(x));

        this.map = L.map('map', {
            center: this.props.center,
            zoom: this.props.zoom,
        });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 18
        }).addTo(this.map);

        this.markerLayer = L.featureGroup([]);
        this.markerLayer.addTo(this.map);

        this.map.on('moveend', (ev) => {
            this.handleMapMove(ev);
        });

        this.updateMarkers();
    }

    componentDidUpdate(prevProps, prevState) {
        if (prevProps.center !== this.props.center) {
            this.map.panTo(this.props.center);
        }

        if (prevProps.zoom !== this.props.zoom) {
            this.map.setZoom(this.props.zoom);
        }

        if (prevProps.markers !== this.props.markers) {
            this.updateMarkers(prevProps.markers);
        }
    }

    handleMapMove() {
        if (this.onMapChange) {
            this.onMapChange({
                bounds: this.map.getBounds(),
                zoom: this.map.getZoom(),
                center: this.map.getCenter(),
            });
        }
    }

    updateMarkers(previousMarkers) {
    }

    render() {
        return <div id='map'></div>;
    }

    createIcon(id) {
        L.icon({
            iconUrl: 'foo.gif',//require(`../../img/map/${id}.gif`),
            shadowUrl: null,
            iconSize:     [32, 32], // size of the icon
            shadowSize:   [0, 0],   // size of the shadow
            iconAnchor:   [16, 16], // point of the icon which will correspond to marker's location
            shadowAnchor: [0, 0],   // the same for the shadow
            popupAnchor:  [0, -16], // point from which the popup should open relative to the iconAnchor
        });
    }
}
