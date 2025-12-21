# Project Mutation Guide

This document explains how to mutate projects for a merchant within this codebase. It covers updating the project's title and uploading pictures.

## Project and Product Equivalence

In this application, what is conceptually a "project" for a merchant is implemented as a "product" in the data model and code. Therefore, to mutate a project, you will need to use the mutations and components related to products.

The main file for handling project/product updates is `containers/products/edit/index.tsx`. This container fetches product data and provides the logic for updating it.

## Updating a Project's Title

To update the title of a project (i.e., a product), you need to use the `UpdateProduct` GraphQL mutation. This mutation takes an input object with the product's ID and the new data to be updated, including the title.

The `onSubmit` function in `containers/products/edit/index.tsx` demonstrates how to do this:

```typescript
// containers/products/edit/index.tsx

const onSubmit = useCallback(async (data: FormValues) => {
  try {
    await client.mutate({
      mutation: UpdateProductDocument,
      variables: {
        input: {
          id: productId,
          categoryId: data.categoryId,
          description: data.description,
          status: data.status,
          tags: data.tags,
          title: data.title, // The new title is passed here
          tracksInventory: data.tracksInventory,
        },
      },
    });

    await refetch();

    toast.like();
  } catch (err) {
    handleError(err);
  }
}, []);
```

The `UpdateProduct` mutation is defined in `graphql/mutations.graphql`:

```graphql
# graphql/mutations.graphql

mutation UpdateProduct($input: VRonUpdateProductInput!) {
  VRonUpdateProduct(input: $input)
}
```

The input type `VRonUpdateProductInput` includes the `title` field.

## Uploading Project Pictures

To upload pictures for a project/product, you need to use the `UploadMediaFiles` GraphQL mutation. This mutation takes the product ID and a list of files to be uploaded.

The `onUploadMedia` function in `containers/products/edit/index.tsx` shows how to handle file uploads:

```typescript
// containers/products/edit/index.tsx

const onUploadMedia = useCallback(async (files: MediaFileFormValues[]) => {
  const newFiles = files
    .filter((mediaFile) => !mediaFile.id)
    .map((mediaFile) => mediaFile.file);

  try {
    await client.mutate({
      mutation: UploadMediaFilesDocument,
      variables: {
        input: {
          productId: productId,
          files: newFiles,
        },
      },
    });

    await refetch();

    toast.like();
  } catch (err) {
    handleError(err);
  }
}, []);
```

The `UploadMediaFiles` mutation is defined in `graphql/mutations.graphql`:

```graphql
# graphql/mutations.graphql

mutation UploadMediaFiles($input: VRonUploadMediaFilesInput!) {
  VRonUploadMediaFiles(input: $input)
}
```

The `VRonUploadMediaFilesInput` type includes the `productId` and a list of `files`.

By following these examples, you can successfully mutate project data for a merchant. Remember to always refer to "products" when working with the codebase.
