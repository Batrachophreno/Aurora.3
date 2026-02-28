import { useBackend } from '../backend';
import { Box, Button, Section, Table, Window } from '../components';

type AlarmRow = {
  name: string;
  ref: string;
};

type Data = {
  priority_alarms: AlarmRow[];
  minor_alarms: AlarmRow[];
};

export const AtmosAlert = (_props, context) => {
  const { act, data } = useBackend<Data>(context);

  const priority = data.priority_alarms || [];
  const minor = data.minor_alarms || [];

  // Merge into one list with a priority flag for UI presentation only.
  const rows: Array<AlarmRow & { priority: boolean }> = [
    ...priority.map((a) => ({ ...a, priority: true })),
    ...minor.map((a) => ({ ...a, priority: false })),
  ];

  return (
    <Window width={500} height={500}>
      <Window.Content scrollable>
        <Section
          title="Atmospheric Alerts"
          buttons={
            <Box>
              <Box inline mr={1} color="bad">
                ● Priority
              </Box>
              <Box inline color="average">
                ● Minor
              </Box>
            </Box>
          }
        >
          <Table>
            <Table.Row header>
              <Table.Cell width="1%">Type</Table.Cell>
              <Table.Cell>Alarm</Table.Cell>
              <Table.Cell width="1%" textAlign="right">
                Actions
              </Table.Cell>
            </Table.Row>

            {rows.length ? (
              rows.map((a) => (
                <Table.Row key={a.ref}>
                  <Table.Cell>
                    <Box color={a.priority ? 'bad' : 'average'}>
                      {a.priority ? 'PRIORITY' : 'MINOR'}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>{a.name}</Table.Cell>
                  <Table.Cell textAlign="right">
                    <Button
                      icon="undo"
                      onClick={() => act('clear_alarm', { alarm: a.ref })}
                    >
                      Reset
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))
            ) : (
              <Table.Row>
                <Table.Cell colSpan={3}>
                  <Box italic>No alerts detected.</Box>
                </Table.Cell>
              </Table.Row>
            )}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};

export default AtmosAlert;
