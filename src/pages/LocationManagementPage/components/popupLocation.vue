<template>
  <q-popup-edit
    class="popupEdit shadow-10"
    square
    buttons
    persistent
    :title="title"
    :label-set="$t('Save')"
    :label-cancel="$t('Cancel')"
    v-model="computedRow"
    @update:model="updateModel"
    @save="saveEdit"
    v-slot="scope"
  >
    <q-input v-model="scope.value.name" dense autofocus :label="$t('Name')" />
    <q-input
      v-model="scope.value.description"
      dense
      :label="$t('Description')"
    />
    <q-input
      v-model="scope.value.view.longitude"
      type="number"
      dense
      :label="$t('Longitude')"
    />
    <q-input
      v-model="scope.value.view.latitude"
      type="number"
      dense
      :label="$t('Latitude')"
    />
    <q-select
      v-model="scope.value.workspace"
      dense
      option-label="name"
      :options="workspaces"
      :label="$t('Workspace')"
    />
    <q-select
      v-model="scope.value.view.projection"
      dense
      option-label="name"
      :options="projections"
      :label="$t('Projection')"
    />
    <!-- Layer Selector -->
    <q-select
      v-if="availableLayers.length > 0"
      v-model="scope.value.mapLayers"
      dense
      multiple
      use-chips
      emit-value
      map-options
      :options="filteredAvailableLayers"
      option-label="name"
      option-value="url"
      :label="$t('Select layers')"
    />
  </q-popup-edit>
</template>

<script>
import {
  defineComponent,
  ref,
  unref,
  getCurrentInstance,
  computed,
} from "vue";
import { useQuasar } from "quasar";
import { i18n } from "boot/i18n.js";
import { transformProjection } from "src/utils/openLayers.js";
import { updateLocation, addLocaction } from "src/api/location";

export default defineComponent({
  name: "PopupLocation",
  props: {
    row: Object,
    locationRows: Array,
    projections: Array,
    workspaces: Array,
    availableLayers: {
      type: Array,
      default: () => [],
    },
  },
  setup(props, { emit }) {
    const vm = getCurrentInstance().proxy;
    const $q = useQuasar();
    const $t = i18n.global.t;
    const computedRow = ref(props.row);

    const title = computed(() => {
      return props.row.id
        ? `${$t("Update location")}: ${unref(computedRow).name}`
        : `${$t("Add location")}:`;
    });

    const filteredAvailableLayers = computed(() => {
      return props.availableLayers.filter(
        (l) => l.workspace === props.row.workspace
      );
    });

    const saveEdit = async (value, _props) => {
      const updateParams = {
        id: value.id,
        view: {},
      };

      if (value.name !== _props.name) updateParams.name = value.name;
      if (value.description !== _props.description)
        updateParams.description = value.description;
      if (value.workspace !== _props.workspace)
        updateParams.workspace = value.workspace;

      if (value.view?.latitude !== _props.view.latitude) {
        updateParams.view.latitude = value.view?.latitude;
      }

      if (value.view?.longitude !== _props.view.longitude) {
        updateParams.view.longitude = value.view?.longitude;
      }

      if (value.view?.projection !== _props.view.projection) {
        updateParams.view.projection = value.view.projection;
      }

      const longLat = transformProjection({
        to: _props.view?.projection?.name || "EPSG:4326",
        definition: _props.view?.projection?.definition || "",
        coordinates: [
          parseFloat(value.view?.longitude || _props.view.longitude),
          parseFloat(value.view?.latitude || _props.view.latitude),
        ],
      });

      updateParams.view.extent = JSON.stringify([
        longLat[0] - 54000,
        longLat[1] - 30000,
        longLat[0] + 50000,
        longLat[1] + 30000,
      ]);

      if (value.mapLayers) updateParams.mapLayers = value.mapLayers;

      if (updateParams.id) {
        const response = await updateLocation(updateParams);
        const currentRow = props.locationRows.find(
          (row) => row.id === response.id
        );
        Object.assign(currentRow, { ...response });
      } else {
        delete updateParams.id;
        await addLocaction(updateParams);
      }
    };

    const updateModel = (val) => {
      console.log(val);
    };

    return {
      computedRow,
      title,
      saveEdit,
      updateModel,
      filteredAvailableLayers,
    };
  },
});
</script>

<style lang="scss">
.popupEdit {
  color: #1976d2;
  width: 50%;
  right: 200px;
  left: 25% !important;
}
</style>
