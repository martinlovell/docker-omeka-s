<?php

require 'bootstrap.php';



use Omeka\Installation\Installer;
use Omeka\Entity\ApiKey;



class InstallMappingModuleTask
{

    public function perform(Installer $installer)
    {
        $omekaModules = $installer->getServiceLocator()->get('Omeka\ModuleManager');
        $module = $omekaModules->getModule('Mapping');
        if ($module) {
            $omekaModules->activate($module);
        } else {
            print("\n\nUnable to install Mapping Module\n\n");
        }
    }
}



/**
 * Install extra RDF vocabularies.
 */
class InstallExtraVocabulariesTask
{
    /**
     * @var array
     */

     protected $vocabularies = [
            // [
            //     'vocabulary' => [
            //         'o:namespace_uri' => 'http://dbpedia.org/ontology/',
            //         'o:prefix' => 'dbo',
            //         'o:label' => 'DBPedia.org',
            //         'o:comment' => '',
            //     ],
            //     'strategy' => 'file',
            //     'file' => '/var/www/html/dbpedia_full.nt',
            //     'format' => 'guess',
            //     'preferred_language' => 'en'
            // ],
            [
                'vocabulary' => [
                    'o:namespace_uri' => 'http://schema.org/',
                    'o:prefix' => 'schema',
                    'o:label' => 'Schema.org',
                    'o:comment' => '',
                ],
                'strategy' => 'file',
                'file' => '/var/www/html/schemaorg.rdf',
                'format' => 'guess',
                'preferred_language' => 'en'
            ],
        ];


    public function perform(Installer $installer)
    {
        $rdfImporter = $installer->getServiceLocator()->get('Omeka\RdfImporter');
        $entityManager = $installer->getServiceLocator()->get('Omeka\EntityManager');

        foreach ($this->vocabularies as $vocabulary) {
            try {
                $response = $rdfImporter->import(
                    $vocabulary['strategy'],
                    $vocabulary['vocabulary'],
                    [
                        'file' => $vocabulary['file'],
                        'format' => $vocabulary['format'],
                        'lang' => $vocabulary['preferred_language'],
                    ]
                );
            } catch (ValidationException $e) {
                $installer->addErrorStore($e->getErrorStore());
                return;
            }
            $entityManager->clear();
        }
    }

    public function getVocabularies()
    {
        return $this->vocabularies;
    }
}



class CreateApiKeyTask
{
    public function perform(Installer $installer)
    {
        $apiManager = $installer->getServiceLocator()->get('Omeka\ApiManager');
        $entityManager = $installer->getServiceLocator()->get('Omeka\EntityManager');
        $userEntity = $entityManager->find('Omeka\Entity\User', 1);


        $key = new ApiKey;
        $key->setId();
        $key->setLabel('Startup API Key');
        $key->setOwner($userEntity);
        $keyId = $key->getId();
        $keyCredential = $key->setCredential();
        $entityManager->persist($key);
        $keyPersisted = true;
        print("\n\nAPI KEY:\n");
        print("Key ID: {$keyId}\n");
        print("Key Credential: {$keyCredential}\n\n");
        $entityManager->flush();
    }
}




$application = \Omeka\Mvc\Application::init(require 'application/config/application.config.php');

$services = $application->getServiceManager();
$status = $services->get('Omeka\Status');
if (!$status->isInstalled()) {
    // Without this, at some point during install the view helper Url
    // will throw an exception 'Request URI has not been set'
    $router = $services->get('Router');
    $router->setRequestUri(new \Laminas\Uri\Http('http://example.com'));

    $installer = $services->get('Omeka\Installer');
    $installer->registerTask(InstallExtraVocabulariesTask::class);
    $installer->registerTask(CreateApiKeyTask::class);
    $installer->registerTask(InstallMappingModuleTask::class);

    if (!$installer->preInstall()) {
        $errors = $installer->getErrors();
        foreach ($errors as $error) {
            fprintf(STDERR, "ERROR: %s\n", $error);
        }
        exit(1);
    }

    $user = [
        'email' => getenv('OMEKA_ADMIN_EMAIL'),
        'name' => getenv('OMEKA_ADMIN_NAME'),
        'password-confirm' => [
            'password' => getenv('OMEKA_ADMIN_PASSWORD'),
        ],
    ];
    $settings = [
        'installation_title' => getenv('OMEKA_INSTALLATION_TITLE') ?: 'Omeka S',
        'time_zone' => getenv('OMEKA_TIME_ZONE') ?: 'UTC',
        'locale' => getenv('OMEKA_LOCALE') ?: '',
    ];

    $installer->registerVars(
        'Omeka\Installation\Task\CreateFirstUserTask',
        $user,
    );
    $installer->registerVars(
        'Omeka\Installation\Task\AddDefaultSettingsTask',
        [
            'administrator_email' => $user['email'],
            'installation_title' => $settings['installation_title'],
            'time_zone' => $settings['time_zone'],
            'locale' => $settings['locale'],
        ]
    );
    if (!$installer->install()) {
        $errors = $installer->getErrors();
        foreach ($errors as $error) {
            fprintf(STDERR, "ERROR: %s at install\n", $error);
        }
        exit(1);
    }
}
