import { Button, LabeledList, Section } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type NeoblobClusterPanelData = {
  neoblob_type: string;
  master_area: string;
  master_coordinates: string;
  growth_count: number;
  expansion_paused: BooleanLike;
  destroyed: BooleanLike;
  has_core: BooleanLike;
};

export const NeoblobClusterPanel = (props) => {
  const { act, data } = useBackend<NeoblobClusterPanelData>();

  return (
    <Window>
      <Window.Content scrollable>
        <Section title="Controls">
          <Button
            content={
              data.expansion_paused
                ? 'Resume Expansion'
                : 'Pause Expansion'
            }
            icon={data.expansion_paused ? 'play' : 'pause'}
            color={data.expansion_paused ? 'good' : 'orange'}
            disabled={data.destroyed}
            onClick={() => act('toggle_expansion')}
          />
          <Button.Confirm
            confirmContent="This will delete all tracked neoblob growth objects. Confirm?"
            icon="exclamation-triangle"
            color="bad"
            disabled={data.destroyed}
            onClick={() => act('destroy_cluster')}
          >
            Destroy Cluster
          </Button.Confirm>
        </Section>

        <Section title="Overview">
          <LabeledList>
            <LabeledList.Item label="Neoblob Type">
              {data.neoblob_type}
            </LabeledList.Item>
            <LabeledList.Item label="Master Nucleus">
              {data.has_core ? data.master_coordinates : 'No master nucleus'}
            </LabeledList.Item>
            <LabeledList.Item label="Area">
              {data.master_area}
            </LabeledList.Item>
            <LabeledList.Item label="Tracked Growth">
              {data.growth_count}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
