import { Box, Button, ByondUi, NoticeBox, Section, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { classes } from 'tgui-core/react';
import { useBackend, useLocalState } from '../backend';
import { NtosWindow } from '../layouts';
import { SearchBar } from './common/SearchBar';

export type CameraData = {
  current_camera: Camera;
  current_network: string;
  networks: Network[];
  cameras: Camera[];
  activeCamera: {
    name: string;
    status: BooleanLike;
  };
  mapRef: string;
};

type Camera = {
  name: string;
  deact: BooleanLike; // deactivated
  camera: string; // ref
  x: number;
  y: number;
  z: number;
};

type Network = {
  tag: string;
  has_access: BooleanLike;
};

export const CameraMonitoring = (props) => {
  const { data } = useBackend<CameraData>();

  return (
    <NtosWindow resizable height={800} width={1100}>
      <NtosWindow.Content>
        <Stack fill>
          <Stack.Item width="390px">
            <Stack fill vertical>
              <Stack.Item>
                {data.networks?.length ? (
                  <ShowNetworks />
                ) : (
                  <NoticeBox>No networks available.</NoticeBox>
                )}
              </Stack.Item>
              <Stack.Item grow basis={0}>
                {data.current_network ? <ShowNetworkCameras /> : ''}
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item grow>
            <CameraFeed />
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

export const ShowNetworks = (props) => {
  const { act, data } = useBackend<CameraData>();

  return (
    <Section
      title="Networks"
      buttons={
        <Button
          content="Reset"
          icon="user-circle"
          onClick={() => act('reset')}
        />
      }
    >
      {data.networks
        .filter((n) => n.has_access)
        .map((network) => (
          <Button
            content={network.tag}
            selected={data.current_network === network.tag}
            key={network.tag}
            onClick={() =>
              act('switch_network', { switch_network: network.tag })
            }
          />
        ))}
    </Section>
  );
};

export const ShowNetworkCameras = (props) => {
  const { act, data } = useBackend<CameraData>();
  const [searchTerm, setSearchTerm] = useLocalState<string>(`searchTerm`, ``);

  return (
    <Section
      fill
      scrollable
      title="Cameras"
      buttons={
        <SearchBar
          autoFocus
          query={searchTerm}
          placeholder="Search by name"
          onSearch={(value) => {
            setSearchTerm(value);
          }}
          style={{ width: '40vw' }}
        />
      }
    >
      {data.cameras?.length ? (
        data.cameras
          .filter(
            (c) => c.name?.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1,
          )
          .map((camera) => (
            <div
              key={camera.camera}
              title={camera.name}
              className={classes([
                'Button',
                'Button--fluid',
                'Button--color--transparent',
                'Button--ellipsis',
                data.current_camera &&
                data.current_camera.camera === camera.camera
                  ? 'Button--selected'
                  : 'candystripe',
                camera.deact && 'Button--disabled',
              ])}
              onClick={() => {
                if (!camera.deact) {
                  act('switch_camera', { switch_camera: camera.camera });
                }
              }}
            >
              {camera.name}
            </div>
          ))
      ) : (
        <NoticeBox>No cameras detected.</NoticeBox>
      )}
    </Section>
  );
};

const getAdjacentCameras = (cameras: Camera[], currentCamera?: Camera) => {
  if (!currentCamera || cameras.length < 2) {
    return [];
  }

  const index = cameras.findIndex((camera) => camera.camera === currentCamera.camera);
  if (index < 0) {
    return [cameras[cameras.length - 1], cameras[0]];
  }

  return [
    cameras[index === 0 ? cameras.length - 1 : index - 1],
    cameras[index === cameras.length - 1 ? 0 : index + 1],
  ];
};

const CameraFeed = (props) => {
  const { act, data } = useBackend<CameraData>();
  const cameras = data.cameras?.filter((camera) => !camera.deact) || [];
  const [previousCamera, nextCamera] = getAdjacentCameras(cameras, data.current_camera);

  return (
    <Section fill>
      <Stack fill vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              {data.activeCamera?.status ? (
                <NoticeBox info>{data.activeCamera.name}</NoticeBox>
              ) : (
                <NoticeBox danger>No input signal</NoticeBox>
              )}
            </Stack.Item>
            <Stack.Item>
              <Button
                disabled={!previousCamera}
                icon="chevron-left"
                onClick={() =>
                  act('switch_camera', {
                    switch_camera: previousCamera.camera,
                  })
                }
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                disabled={!nextCamera}
                icon="chevron-right"
                onClick={() =>
                  act('switch_camera', {
                    switch_camera: nextCamera.camera,
                  })
                }
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item grow>
          {data.mapRef ? (
            <ByondUi
              height="100%"
              width="100%"
              params={{
                id: data.mapRef,
                type: 'map',
              }}
            />
          ) : (
            <Box height="100%" />
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};
