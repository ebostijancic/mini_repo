defmodule MiniRepo.RegistryDiff do
  @moduledoc false

  def diff(mirror, upstream) do
    mirror_packages = Map.keys(mirror)
    upstream_packages = Map.keys(upstream)
    created_packages = upstream_packages -- mirror_packages
    deleted_packages = mirror_packages -- upstream_packages

    releases =
      for name <- mirror_packages -- deleted_packages, into: %{} do
        mirror_versions = Enum.map(mirror[name], & &1.version)
        upstream_versions = upstream[name].versions

        mirror_retired =
          for release <- mirror[name], match?(%{retired: %{reason: _}}, release) do
            release.version
          end

        upstream_retired =
          for index <- upstream[name].retired do
            Enum.at(upstream_versions, index)
          end

        {name,
         %{
           created: sort_versions(upstream_versions -- mirror_versions),
           deleted: sort_versions(mirror_versions -- upstream_versions),
           retired: sort_versions(upstream_retired -- mirror_retired),
           unretired: sort_versions(mirror_retired -- upstream_retired)
         }}
      end

    releases =
      releases
      |> Enum.filter(fn {_name, map} ->
        map.created != [] or
          map.deleted != [] or
          map.retired != [] or
          map.unretired != []
      end)
      |> Enum.into(%{})

    %{
      packages: %{
        created: Enum.sort(created_packages),
        deleted: Enum.sort(deleted_packages)
      },
      releases: releases
    }
  end

  defp sort_versions(list) do
    Enum.sort(list, &Version.compare(&1, &2) == :lt)
  end
end
